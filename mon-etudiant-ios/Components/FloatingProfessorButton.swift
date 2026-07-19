import SwiftUI

struct FloatingProfessorButton: View {
    let action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Ouvrir le Professeur")
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
