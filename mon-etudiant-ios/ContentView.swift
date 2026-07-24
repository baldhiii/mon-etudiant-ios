import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showProfessor = false
    @State private var isInReviewSession = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView(selectedTab: $selectedTab)
                    .tabItem { Label("Aujourd'hui", systemImage: "sun.max.fill") }
                    .tag(0)

                AgendaView()
                    .tabItem { Label("Agenda", systemImage: "calendar") }
                    .tag(1)

                AssignmentsView()
                    .tabItem { Label("Devoirs", systemImage: "checklist") }
                    .tag(2)

                ReviewsView(isInReviewSession: $isInReviewSession)
                    .tabItem { Label("Révisions", systemImage: "rectangle.stack.fill") }
                    .tag(3)
            }

            if !isInReviewSession {
                // GeometryReader transparent : fournit la taille au bouton sans bloquer les touches
                GeometryReader { geo in
                    FloatingProfessorButton(containerSize: geo.size) {
                        showProfessor = true
                    }
                }
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
