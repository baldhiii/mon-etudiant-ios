import SwiftUI
import SwiftData

// MARK: - AgendaView

struct AgendaView: View {
    @State private var selectedDay: Int = Self.todayWeekday()
    @State private var courseFormItem: CourseFormItem?

    static let orderedDays: [(Int, String)] = [
        (2, "Lun"), (3, "Mar"), (4, "Mer"), (5, "Jeu"), (6, "Ven"), (7, "Sam"), (1, "Dim")
    ]

    static func todayWeekday() -> Int {
        Calendar.current.component(.weekday, from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DaySelectorView(days: Self.orderedDays, selectedDay: $selectedDay)

                CourseListView(dayOfWeek: selectedDay) { session in
                    courseFormItem = CourseFormItem(session: session, defaultDay: session.dayOfWeek)
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        courseFormItem = CourseFormItem(session: nil, defaultDay: selectedDay)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un cours")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExamsView()
                    } label: {
                        Image(systemName: "graduationcap")
                    }
                    .accessibilityLabel("Examens")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Matières") {
                        SubjectsView()
                    }
                }
            }
            .sheet(item: $courseFormItem) { item in
                CourseFormView(session: item.session, defaultDay: item.defaultDay)
            }
        }
    }
}

// MARK: - CourseFormItem

struct CourseFormItem: Identifiable {
    let id = UUID()
    let session: CourseSession?
    let defaultDay: Int
}

// MARK: - DaySelectorView

private struct DaySelectorView: View {
    let days: [(Int, String)]
    @Binding var selectedDay: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(days, id: \.0) { dayInt, label in
                    Button {
                        selectedDay = dayInt
                    } label: {
                        VStack(spacing: 4) {
                            Text(label)
                                .font(.subheadline)
                                .fontWeight(selectedDay == dayInt ? .semibold : .regular)
                                .foregroundStyle(selectedDay == dayInt ? Color.accentColor : .primary)
                            Capsule()
                                .fill(selectedDay == dayInt ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        Divider()
    }
}

// MARK: - CourseListView

private struct CourseListView: View {
    let dayOfWeek: Int
    let onEdit: (CourseSession) -> Void

    @Environment(\.modelContext) private var context
    @Query var sessions: [CourseSession]

    init(dayOfWeek: Int, onEdit: @escaping (CourseSession) -> Void) {
        self.dayOfWeek = dayOfWeek
        self.onEdit = onEdit
        _sessions = Query(
            filter: #Predicate<CourseSession> { session in
                session.dayOfWeek == dayOfWeek
            },
            sort: \CourseSession.startTime
        )
    }

    var body: some View {
        if sessions.isEmpty {
            EmptyStateView(
                systemImage: "calendar",
                title: "Semaine vide",
                message: "Ajoute tes cours, ils apparaîtront ici jour par jour.",
                actionLabel: nil
            )
        } else {
            List {
                ForEach(sessions) { session in
                    CourseCardView(session: session)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit(session) }
                }
                .onDelete { indexSet in
                    indexSet.forEach { context.delete(sessions[$0]) }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - CourseCardView

private struct CourseCardView: View {
    let session: CourseSession

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(session.subject?.colorName ?? "AccentColor"))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(timeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(session.subject?.name ?? "Matière inconnue")
                    .font(.headline)
                if !session.room.isEmpty {
                    Text(session.room)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Spacer()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: session.startTime))–\(f.string(from: session.endTime))"
    }
}
