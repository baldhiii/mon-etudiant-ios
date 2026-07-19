import SwiftUI
import SwiftData

struct ExamFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let exam: Exam?

    @State private var title: String
    @State private var selectedSubject: Subject?
    @State private var date: Date
    @State private var coefficientText: String

    @Query(sort: \Subject.name) private var subjects: [Subject]

    init(exam: Exam?) {
        self.exam = exam
        _title = State(initialValue: exam?.title ?? "")
        _selectedSubject = State(initialValue: exam?.subject)
        _date = State(initialValue: exam?.date ?? Date())
        let c = exam?.coefficient ?? 1.0
        _coefficientText = State(initialValue: c == 1.0 ? "1" : String(format: "%.2g", c))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Titre") {
                    TextField("Devoir surveillé, Partiel…", text: $title)
                }

                Section("Matière") {
                    Picker("Matière", selection: $selectedSubject) {
                        Text("Aucune").tag(Optional<Subject>.none)
                        ForEach(subjects) { s in
                            Text(s.name).tag(Optional(s))
                        }
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }

                Section {
                    HStack {
                        Text("Coefficient")
                        Spacer()
                        TextField("1", text: $coefficientText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
            }
            .navigationTitle(exam == nil ? "Nouvel examen" : "Modifier l'examen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") { save() }
                        .bold()
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let coeff = Double(coefficientText.replacingOccurrences(of: ",", with: ".")) ?? 1.0

        if let exam {
            exam.title = trimmed
            exam.subject = selectedSubject
            exam.date = date
            exam.coefficient = coeff
        } else {
            context.insert(Exam(
                title: trimmed,
                date: date,
                coefficient: coeff,
                subject: selectedSubject
            ))
        }
        dismiss()
    }
}
