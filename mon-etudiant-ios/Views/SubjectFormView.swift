import SwiftUI
import SwiftData

struct SubjectFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let subject: Subject?

    @State private var name: String
    @State private var selectedColor: String

    private static let colorNames = [
        "SubjectRed", "SubjectOrange", "SubjectAmber", "SubjectGreen",
        "SubjectTeal", "SubjectBlue", "SubjectPurple", "SubjectPink"
    ]

    init(subject: Subject?) {
        self.subject = subject
        _name = State(initialValue: subject?.name ?? "")
        _selectedColor = State(initialValue: subject?.colorName ?? "SubjectBlue")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Mathématiques, Physique…", text: $name)
                }
                Section("Couleur") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 4),
                        spacing: 16
                    ) {
                        ForEach(Self.colorNames, id: \.self) { colorName in
                            ColorSwatchButton(
                                colorName: colorName,
                                isSelected: selectedColor == colorName
                            ) { selectedColor = colorName }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(subject == nil ? "Nouvelle matière" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") { save() }
                        .bold()
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let subject {
            subject.name = trimmed
            subject.colorName = selectedColor
        } else {
            context.insert(Subject(name: trimmed, colorName: selectedColor))
        }
        dismiss()
    }
}

private struct ColorSwatchButton: View {
    let colorName: String
    let isSelected: Bool
    let action: () -> Void

    private static let displayNames: [String: String] = [
        "SubjectRed": "Rouge", "SubjectOrange": "Orange", "SubjectAmber": "Ambre",
        "SubjectGreen": "Vert", "SubjectTeal": "Sarcelle", "SubjectBlue": "Bleu",
        "SubjectPurple": "Violet", "SubjectPink": "Rose"
    ]

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(colorName))
                    .frame(width: 44, height: 44)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.displayNames[colorName] ?? colorName)
    }
}
