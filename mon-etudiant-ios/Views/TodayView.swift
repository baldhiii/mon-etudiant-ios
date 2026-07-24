import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var selectedTab: Int

    @Query private var pendingAssignments: [Assignment]
    @Query private var todaySessions: [CourseSession]
    @Query private var allCards: [Flashcard]
    @Query(sort: \Exam.date) private var allExams: [Exam]
    @Query private var profiles: [UserProfile]

    @State private var showSettings = false

    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        _todaySessions = Query(
            filter: #Predicate<CourseSession> { session in session.dayOfWeek == todayWeekday },
            sort: \CourseSession.startTime
        )
        _pendingAssignments = Query(
            filter: #Predicate<Assignment> { assignment in assignment.isDone == false },
            sort: \Assignment.dueDate
        )
    }

    // MARK: - Computed

    private var profile: UserProfile? { profiles.first }

    private var navigationTitle: String {
        if let name = profile?.firstName, !name.isEmpty {
            return "Salut, \(name) 👋"
        }
        return "Aujourd'hui"
    }

    private var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        f.locale = Locale(identifier: "fr_FR")
        return f.string(from: Date())
    }

    private var dueCardsCount: Int {
        let startOfTomorrow = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: .now)
        )!
        return allCards.filter { $0.dueDate < startOfTomorrow }.count
    }

    private var upcomingCourses: [CourseSession] {
        let now = Self.normalizedTimeNow()
        return Array(todaySessions.filter { $0.startTime >= now }.prefix(3))
    }

    private var nextAssignments: [Assignment] {
        Array(pendingAssignments.prefix(3))
    }

    private var nextExam: Exam? {
        let now = Date()
        return allExams.first { $0.date > now }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(todayFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Deux compteurs
                    HStack(spacing: 16) {
                        TodayCounterCard(
                            count: pendingAssignments.count,
                            label: "devoirs à faire"
                        ) { selectedTab = 2 }

                        TodayCounterCard(
                            count: dueCardsCount,
                            label: "cartes à revoir"
                        ) { selectedTab = 3 }
                    }

                    // Prochains cours
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prochains cours")
                            .font(.title2).bold()
                        if upcomingCourses.isEmpty {
                            Text("Pas de cours aujourd'hui.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(upcomingCourses) { session in
                                TodayCourseCard(session: session)
                            }
                        }
                    }

                    // À rendre bientôt
                    if !nextAssignments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("À rendre bientôt")
                                .font(.title2).bold()
                            ForEach(nextAssignments) { assignment in
                                TodayAssignmentCard(assignment: assignment)
                            }
                        }
                    }

                    // Prochain examen
                    if let exam = nextExam {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Prochain examen")
                                .font(.title2).bold()
                            TodayExamCard(exam: exam)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Réglages")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Helpers

    private static func normalizedTimeNow() -> Date {
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute], from: Date())
        return cal.date(from: DateComponents(
            year: 2000, month: 1, day: 1,
            hour: c.hour ?? 0, minute: c.minute ?? 0
        )) ?? Date()
    }
}

// MARK: - Subviews

private struct TodayCounterCard: View {
    let count: Int
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(count > 0 ? Color.primary : Color.secondary)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct TodayCourseCard: View {
    let session: CourseSession

    private var subjectColor: Color {
        Color(session.subject?.colorName ?? "AccentColor")
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(subjectColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? "—")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("\(formatTime(session.startTime))–\(formatTime(session.endTime))")
                    if !session.room.isEmpty {
                        Text("· \(session.room)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 12)

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TodayAssignmentCard: View {
    let assignment: Assignment

    private var subjectColor: Color {
        Color(assignment.subject?.colorName ?? "AccentColor")
    }

    private var urgency: (icon: String, color: Color)? {
        let now = Date()
        let in24h = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        if assignment.dueDate < now {
            return ("exclamationmark.triangle.fill", Color("SemanticError"))
        } else if assignment.dueDate <= in24h {
            return ("exclamationmark.triangle.fill", Color("SemanticWarning"))
        }
        return nil
    }

    private var relativeDue: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let target = cal.startOfDay(for: assignment.dueDate)
        let diff = cal.dateComponents([.day], from: today, to: target).day ?? 0
        if diff < 0 { return "en retard" }
        if diff == 0 { return "aujourd'hui" }
        if diff == 1 { return "demain" }
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        f.locale = Locale(identifier: "fr_FR")
        return f.string(from: assignment.dueDate)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(subjectColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(.headline)
                    .lineLimit(1)
                if let name = assignment.subject?.name {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                if let u = urgency {
                    Image(systemName: u.icon)
                        .foregroundStyle(u.color)
                        .font(.caption)
                }
                Text(relativeDue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TodayExamCard: View {
    let exam: Exam

    private var subjectColor: Color {
        Color(exam.subject?.colorName ?? "AccentColor")
    }

    private var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let target = cal.startOfDay(for: exam.date)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(subjectColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(exam.title)
                    .font(.headline)
                    .lineLimit(1)
                if let name = exam.subject?.name {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(daysUntil == 0 ? "aujourd'hui" : "dans \(daysUntil) j")
                .font(.subheadline)
                .foregroundStyle(daysUntil <= 7 ? Color("SemanticWarning") : .secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
