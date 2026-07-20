import SwiftUI

struct FloatingProfessorButton: View {
    let containerSize: CGSize
    let action: () -> Void

    // Position persistée en ratios (0–1) pour s'adapter à tout écran
    @AppStorage("prof_btn_x_ratio") private var storedXRatio: Double = -1.0
    @AppStorage("prof_btn_y_ratio") private var storedYRatio: Double = -1.0

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let buttonSize: CGFloat = 56
    private let edgeMargin: CGFloat = 20
    private let tabBarClearance: CGFloat = 65  // hauteur tab bar + marge

    // Position par défaut : bas droite au-dessus de la tab bar
    private var defaultPos: CGPoint {
        CGPoint(
            x: containerSize.width  - buttonSize / 2 - edgeMargin,
            y: containerSize.height - buttonSize / 2 - tabBarClearance
        )
    }

    // Position sauvegardée (ou default si premier lancement)
    private var basePos: CGPoint {
        guard storedXRatio >= 0 else { return defaultPos }
        return CGPoint(
            x: storedXRatio * containerSize.width,
            y: storedYRatio * containerSize.height
        )
    }

    private var currentPos: CGPoint {
        CGPoint(
            x: basePos.x + dragOffset.width,
            y: basePos.y + dragOffset.height
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: buttonSize, height: buttonSize)
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(
            color: Color.accentColor.opacity(isDragging ? 0.55 : 0.35),
            radius: isDragging ? 16 : 8,
            x: 0, y: isDragging ? 8 : 4
        )
        .scaleEffect(isDragging ? 1.12 : 1.0)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: isDragging)
        .position(currentPos)
        // Tap : ouvre le Professeur (bloqué si drag en cours)
        .onTapGesture {
            guard !isDragging else { return }
            action()
        }
        // Drag : repositionne le bouton
        .simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if !isDragging { isDragging = true }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let half = buttonSize / 2
                    var newX = basePos.x + value.translation.width
                    var newY = basePos.y + value.translation.height

                    // Clamp dans les limites de l'écran
                    newX = max(half + edgeMargin,
                               min(containerSize.width  - half - edgeMargin, newX))
                    newY = max(half + edgeMargin,
                               min(containerSize.height - half - tabBarClearance, newY))

                    withAnimation(.spring(duration: 0.3, bounce: 0.25)) {
                        storedXRatio = newX / containerSize.width
                        storedYRatio = newY / containerSize.height
                        dragOffset = .zero
                    }
                    // Délai pour que le guard dans onTapGesture bloque le tap post-drag
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isDragging = false
                    }
                }
        )
        .accessibilityLabel("Ouvrir le Professeur")
        .accessibilityAddTraits(.isButton)
    }
}
