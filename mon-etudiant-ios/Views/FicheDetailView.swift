import SwiftUI

struct FicheDetailView: View {
    let fiche: Fiche

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fiche.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                markdownView(fiche.markdownContent)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(fiche.title)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func markdownView(_ md: String) -> some View {
        if let attr = try? AttributedString(
            markdown: md,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attr)
                .textSelection(.enabled)
        } else {
            Text(md)
                .textSelection(.enabled)
        }
    }
}
