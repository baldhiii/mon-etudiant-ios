import SwiftUI
import SwiftData

struct CourseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: CourseSession?
    let defaultDay: Int

    @State private var selectedSubject: Subject?
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var room: String
    @State private var selectedDays: Set<Int>

    @Query(sort: \Subject.name) private var subjects: [Subject]

    private static let orderedDays: [(Int, String)] = [
        (2, "Lun"), (3, "Mar"), (4, "Mer"), (5, "Jeu"), (6, "Ven"), (7, "Sam"), (1, "Dim")
    ]

    init(session: CourseSession?, defaultDay: Int) {
        self.session = session
        self.defaultDay = defaultDay
        _startTime = State(initialValue: session?.startTime ?? Self.fixedTime(hour: 8))
        _endTime   = State(initialValue: session?.endTime   ?? Self.fixedTime(hour: 9))
        _room      = State(initialValue: session?.room ?? "")
        _selectedSubject = State(initialValue: session?.subject)
        _selectedDays    = State(initialValue: [session?.dayOfWeek ?? defaultDay])
    }

    private static func fixedTime(hour: Int) -> Date {
        // Store times on a fixed epoch so sorting stays consistent
        Calendar.current.date(
            from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: 0)
        ) ?? Date()
    }

    private var isEditMode: Bool { session != nil }
    private var canSave: Bool { selectedSubject != nil && !selectedDays.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Matière") {
                    if subjects.isEmpty {
                        Text("Aucune matière — crée d'abord une matière via Agenda › Matières.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Matière", selection: $selectedSubject) {
                            Text("Choisir…").tag(Optional<Subject>.none)
                            ForEach(subjects) { s in
                                Label {
                                    Text(s.name)
                                } icon: {
                                    Circle()
                                        .fill(Color(s.colorName))
                                        .frame(width: 10, height: 10)
                                }
                                .tag(Optional(s))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.inline)
                    }
                }

                if isEditMode {
                    Section("Jour") {
                        Picker("Jour", selection: Binding(
                            get: { selectedDays.first ?? defaultDay },
                            set: { selectedDays = [$0] }
                        )) {
                            ForEach(Self.orderedDays, id: \.0) { dayInt, label in
                                Text(label).tag(dayInt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Section("Jour(s)") {
                        ForEach(Self.orderedDays, id: \.0) { dayInt, label in
                            Toggle(label, isOn: Binding(
                                get: { selectedDays.contains(dayInt) },
                                set: { on in
                                    if on { selectedDays.insert(dayInt) }
                                    else  { selectedDays.remove(dayInt) }
                                }
                            ))
                        }
                    }
                }

                Section("Horaire") {
                    DatePicker("Début", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Fin",   selection: $endTime,   displayedComponents: .hourAndMinute)
                }

                Section("Salle") {
                    TextField("Optionnel (ex. B203)", text: $room)
                }
            }
            .navigationTitle(isEditMode ? "Modifier le cours" : "Nouveau cours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let normStart = normalizedTime(startTime)
        let normEnd   = normalizedTime(endTime)

        if let session {
            session.subject   = selectedSubject
            session.dayOfWeek = selectedDays.first ?? defaultDay
            session.startTime = normStart
            session.endTime   = normEnd
            session.room      = room
        } else {
            for day in selectedDays {
                context.insert(CourseSession(
                    dayOfWeek: day,
                    startTime: normStart,
                    endTime: normEnd,
                    room: room,
                    subject: selectedSubject
                ))
            }
        }
        dismiss()
    }

    // Normalize to fixed epoch so sorting by startTime works by time-of-day only
    private func normalizedTime(_ date: Date) -> Date {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Calendar.current.date(
            from: DateComponents(year: 2000, month: 1, day: 1, hour: c.hour, minute: c.minute)
        ) ?? date
    }
}
