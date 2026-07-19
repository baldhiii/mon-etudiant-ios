import SwiftUI
import SwiftData
import UIKit

struct AssignmentsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]

    @State private var selectedTab = 0          // 0 = À faire, 1 = Faits
    @State private var showForm = false
    @State private var editAssignment: Assignment?
    @State private var animatingDoneIDs: Set<PersistentIdentifier> = []

    // MARK: - Computed sections

    private var startOfToday: Date { Calendar.current.startOfDay(for: Date()) }
    private var weekCutoff: Date   {
        Calendar.current.date(byAdding: .day, value: 7, to: startOfToday) ?? startOfToday
    }

    private var todoAssignments: [Assignment]  { assignments.filter { !$0.isDone } }
    private var doneAssignments: [Assignment]  { assignments.filter { $0.isDone } }
    private var lateAssignments: [Assignment]  { todoAssignments.filter { $0.dueDate < startOfToday } }
    private var weekAssignments: [Assignment]  { todoAssignments.filter { $0.dueDate >= startOfToday && $0.dueDate < weekCutoff } }
    private var laterAssignments: [Assignment] { todoAssignments.filter { $0.dueDate >= weekCutoff } }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("À faire").tag(0)
                    Text("Faits").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                Divider()

                if selectedTab == 0 { todoView }
                else                { doneView }
            }
            .navigationTitle("Devoirs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showForm = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un devoir")
                }
            }
            .sheet(isPresented: $showForm) {
                AssignmentFormView(assignment: nil)
            }
            .sheet(item: $editAssignment) { a in
                AssignmentFormView(assignment: a)
            }
        }
    }

    // MARK: - À faire

    @ViewBuilder
    private var todoView: some View {
        if lateAssignments.isEmpty && weekAssignments.isEmpty && laterAssignments.isEmpty {
            EmptyStateView(
                systemImage: "checklist",
                title: "Rien à faire",
                message: "Tout est à jour. Profite, ou prends de l'avance.",
                actionLabel: "Ajouter un devoir"
            ) { showForm = true }
        } else {
            List {
                assignmentSection(
                    title: "En retard",
                    headerColor: Color("SemanticError"),
                    items: lateAssignments
                )
                assignmentSection(
                    title: "Cette semaine",
                    headerColor: .primary,
                    items: weekAssignments
                )
                assignmentSection(
                    title: "Plus tard",
                    headerColor: .primary,
                    items: laterAssignments
                )
            }
            .listStyle(.insetGrouped)
            .animation(.default, value: animatingDoneIDs.isEmpty)
        }
    }

    @ViewBuilder
    private func assignmentSection(
        title: String,
        headerColor: Color,
        items: [Assignment]
    ) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { a in
                    AssignmentRow(
                        assignment: a,
                        isChecked: animatingDoneIDs.contains(a.persistentModelID)
                    ) { check(a) }
                    .contentShape(Rectangle())
                    .onTapGesture { editAssignment = a }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { check(a) } label: {
                            Label("Fait", systemImage: "checkmark")
                        }
                        .tint(Color("SemanticSuccess"))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(a) } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text(title)
                    .font(.title2).bold()
                    .foregroundStyle(headerColor)
                    .textCase(nil)
            }
        }
    }

    // MARK: - Faits

    @ViewBuilder
    private var doneView: some View {
        if doneAssignments.isEmpty {
            EmptyStateView(
                systemImage: "checkmark.circle",
                title: "Aucun devoir complété",
                message: "Tes devoirs cochés apparaîtront ici.",
                actionLabel: nil
            )
        } else {
            List {
                ForEach(doneAssignments) { a in
                    AssignmentRow(assignment: a, isChecked: true, onCheck: nil)
                        .contentShape(Rectangle())
                        .onTapGesture { editAssignment = a }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { delete(a) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Actions

    private func check(_ assignment: Assignment) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { animatingDoneIDs.formUnion([assignment.persistentModelID]) }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            assignment.isDone = true
            NotificationService.cancel(for: assignment)
            animatingDoneIDs.remove(assignment.persistentModelID)
        }
    }

    private func delete(_ assignment: Assignment) {
        NotificationService.cancel(for: assignment)
        context.delete(assignment)
    }
}

// MARK: - AssignmentRow

private struct AssignmentRow: View {
    let assignment: Assignment
    let isChecked: Bool
    let onCheck: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            if let onCheck {
                Button(action: onCheck) {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isChecked ? Color("SemanticSuccess") : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isChecked ? "Annuler" : "Marquer comme fait")
            }

            if let subject = assignment.subject {
                Circle()
                    .fill(Color(subject.colorName))
                    .frame(width: 8, height: 8)
            }

            Text(assignment.title)
                .font(.body)
                .lineLimit(1)
                .strikethrough(isChecked || assignment.isDone, color: .secondary)
                .foregroundStyle((isChecked || assignment.isDone) ? Color.secondary : .primary)

            Spacer()

            Text(relativeDueDate(assignment.dueDate))
                .font(.caption)
                .foregroundStyle(dueDateColor(assignment.dueDate))
        }
        .padding(.vertical, 2)
    }

    // MARK: Helpers

    private func relativeDueDate(_ date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dueDay = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: dueDay).day ?? 0
        switch days {
        case -1:     return "hier"
        case 0:      return "aujourd'hui"
        case 1:      return "demain"
        case 2...6:
            let f = DateFormatter()
            f.locale = Locale(identifier: "fr_FR")
            f.dateFormat = "EEE" // "lun.", "mar."…
            return f.string(from: date)
        default:
            let f = DateFormatter()
            f.locale = Locale(identifier: "fr_FR")
            f.dateFormat = "d MMM"
            return f.string(from: date)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dueDay = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: dueDay).day ?? 0
        if days < 0  { return Color("SemanticError") }
        if days <= 1 { return Color("SemanticWarning") }
        return .secondary
    }
}
