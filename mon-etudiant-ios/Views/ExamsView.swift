import SwiftUI
import SwiftData

struct ExamsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exam.date) private var exams: [Exam]

    @State private var showNewSheet = false
    @State private var editExam: Exam?

    var body: some View {
        Group {
            if exams.isEmpty {
                EmptyStateView(
                    systemImage: "graduationcap",
                    title: "Aucun examen",
                    message: "Ajoute tes examens pour ne rien rater.",
                    actionLabel: "Ajouter un examen"
                ) { showNewSheet = true }
            } else {
                List {
                    ForEach(exams) { exam in
                        ExamRow(exam: exam)
                            .contentShape(Rectangle())
                            .onTapGesture { editExam = exam }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { context.delete(exams[$0]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Examens")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewSheet = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter un examen")
            }
        }
        .sheet(isPresented: $showNewSheet) {
            ExamFormView(exam: nil)
        }
        .sheet(item: $editExam) { exam in
            ExamFormView(exam: exam)
        }
    }
}

private struct ExamRow: View {
    let exam: Exam

    var body: some View {
        let (label, isWarning) = Self.countdown(to: exam.date)
        HStack(spacing: 12) {
            Circle()
                .fill(exam.subject.map { Color($0.colorName) } ?? Color.secondary)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(exam.title.isEmpty ? "Sans titre" : exam.title)
                    .font(.headline)
                if let subject = exam.subject {
                    Text(subject.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(label)
                .font(.caption)
                .foregroundStyle(isWarning ? Color("SemanticWarning") : Color.secondary)
        }
        .padding(.vertical, 4)
    }

    static func countdown(to date: Date) -> (String, Bool) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: target).day ?? 0
        switch days {
        case ..<0: return ("Passé", false)
        case 0:    return ("Aujourd'hui", true)
        case 1:    return ("Demain", true)
        default:   return ("dans \(days) jours", days <= 7)
        }
    }
}
