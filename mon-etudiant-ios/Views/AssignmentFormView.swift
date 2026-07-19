import SwiftUI
import SwiftData
import UserNotifications

struct AssignmentFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let assignment: Assignment?

    @State private var title: String
    @State private var selectedSubject: Subject?
    @State private var dueDate: Date
    @State private var reminderType: Int
    @State private var note: String
    @State private var notificationsDisabled = false

    @Query(sort: \Subject.name) private var subjects: [Subject]

    private static let reminderLabels = ["Aucun", "La veille", "Le jour J"]

    init(assignment: Assignment?) {
        self.assignment = assignment
        _title          = State(initialValue: assignment?.title ?? "")
        _selectedSubject = State(initialValue: assignment?.subject)
        _dueDate        = State(initialValue: assignment?.dueDate ?? Date())
        _reminderType   = State(initialValue: assignment?.reminderType ?? 0)
        _note           = State(initialValue: assignment?.note ?? "")
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Titre") {
                    TextField("Dissertation, Exercices ch.4…", text: $title)
                }

                Section("Matière") {
                    Picker("Matière", selection: $selectedSubject) {
                        Text("Aucune").tag(Optional<Subject>.none)
                        ForEach(subjects) { s in
                            Text(s.name).tag(Optional(s))
                        }
                    }
                }

                Section("Échéance") {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }

                Section {
                    Picker("Rappel", selection: $reminderType) {
                        ForEach(0..<Self.reminderLabels.count, id: \.self) { i in
                            Text(Self.reminderLabels[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)

                    if notificationsDisabled && reminderType != 0 {
                        Label("Rappels désactivés dans Réglages", systemImage: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Rappel")
                }

                Section("Note (optionnel)") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(assignment == nil ? "Nouveau devoir" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") { Task { await save() } }
                        .bold()
                        .disabled(!isValid)
                }
            }
            .task { await refreshNotifStatus() }
            .onChange(of: reminderType) { _, newValue in
                if newValue != 0 { Task { await refreshNotifStatus() } }
            }
        }
    }

    // MARK: - Private

    private func refreshNotifStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDisabled = settings.authorizationStatus == .denied
    }

    private func save() async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let assignment {
            assignment.title       = trimmed
            assignment.subject     = selectedSubject
            assignment.dueDate     = dueDate
            assignment.reminderType = reminderType
            assignment.note        = note
            await NotificationService.schedule(for: assignment)
        } else {
            let a = Assignment(
                title: trimmed,
                dueDate: dueDate,
                note: note,
                reminderType: reminderType,
                subject: selectedSubject
            )
            context.insert(a)
            await NotificationService.schedule(for: a)
        }
        dismiss()
    }
}
