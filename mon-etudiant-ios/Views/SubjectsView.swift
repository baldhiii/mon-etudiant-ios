import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var showNewSheet = false
    @State private var deleteTarget: Subject?

    var body: some View {
        Group {
            if subjects.isEmpty {
                EmptyStateView(
                    systemImage: "books.vertical",
                    title: "Aucune matière",
                    message: "Ajoute tes matières pour organiser tout le reste.",
                    actionLabel: "Ajouter une matière"
                ) { showNewSheet = true }
            } else {
                List {
                    ForEach(subjects) { subject in
                        NavigationLink {
                            SubjectDetailView(subject: subject)
                        } label: {
                            SubjectRow(subject: subject)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTarget = subject
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Matières")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewSheet = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ajouter une matière")
            }
        }
        .sheet(isPresented: $showNewSheet) {
            SubjectFormView(subject: nil)
        }
        .confirmationDialog(
            "Supprimer « \(deleteTarget?.name ?? "") » ?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                if let s = deleteTarget { context.delete(s) }
                deleteTarget = nil
            }
        } message: {
            Text("Les cours et fiches liés seront également supprimés.")
        }
    }
}

private struct SubjectRow: View {
    let subject: Subject
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(subject.colorName))
                .frame(width: 10, height: 10)
            Text(subject.name)
                .font(.body)
        }
    }
}
