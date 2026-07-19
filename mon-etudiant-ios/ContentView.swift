import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showProfessor = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Aujourd'hui", systemImage: "sun.max.fill")
                    }
                    .tag(0)

                AgendaView()
                    .tabItem {
                        Label("Agenda", systemImage: "calendar")
                    }
                    .tag(1)

                AssignmentsView()
                    .tabItem {
                        Label("Devoirs", systemImage: "checklist")
                    }
                    .tag(2)

                ReviewsView()
                    .tabItem {
                        Label("Révisions", systemImage: "rectangle.stack.fill")
                    }
                    .tag(3)
            }

            FloatingProfessorButton {
                showProfessor = true
            }
        }
        .fullScreenCover(isPresented: $showProfessor) {
            ProfessorView()
        }
    }
}

#Preview {
    ContentView()
}
