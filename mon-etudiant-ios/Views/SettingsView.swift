import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]

    @AppStorage("reminder_eve_hour")   private var storedEveHour:   Int = 18
    @AppStorage("reminder_eve_minute") private var storedEveMinute: Int = 0
    @AppStorage("reminder_dday_hour")   private var storedDdayHour:   Int = 7
    @AppStorage("reminder_dday_minute") private var storedDdayMinute: Int = 0

    @State private var firstName = ""
    @State private var schoolLevel = "Lycée"
    @State private var eveTime: Date = Date()
    @State private var ddayTime: Date = Date()
    @State private var quota: QuotaResponse?
    @State private var isLoadingQuota = false

    #if DEBUG
    @State private var devToken = ""
    #endif

    private let levels = ["Collège", "Lycée", "Études supérieures", "Autodidacte"]

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                remindersSection
                if authService.isAuthenticated {
                    quotaSection
                }
                #if DEBUG
                devSection
                #endif
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { save() }
                }
            }
            .onAppear { load() }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profil") {
            TextField("Prénom", text: $firstName)
            Picker("Niveau scolaire", selection: $schoolLevel) {
                ForEach(levels, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    private var remindersSection: some View {
        Section {
            DatePicker("Rappel la veille (J-1)", selection: $eveTime, displayedComponents: .hourAndMinute)
            DatePicker("Rappel le jour J", selection: $ddayTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("Rappels de devoirs")
        } footer: {
            Text("Ces horaires s'appliquent aux nouvelles notifications.")
                .font(.caption)
        }
    }

    private var quotaSection: some View {
        Section("Quota IA") {
            if isLoadingQuota {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let q = quota {
                LabeledContent("Utilisés aujourd'hui") { Text("\(q.usedToday) / \(q.dailyLimit)") }
                LabeledContent("Réinitialisation") {
                    Text(q.resetsAt, format: .dateTime.hour().minute())
                }
            } else {
                Button("Vérifier le quota") { loadQuota() }
            }
        }
    }

    #if DEBUG
    private var devSection: some View {
        Section {
            TextField("Colle un jeton forgé ici", text: $devToken)
                .font(.caption.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Appliquer le jeton") { applyDevToken() }
                .disabled(devToken.trimmingCharacters(in: .whitespaces).isEmpty)
            if authService.isAuthenticated {
                Button("Se déconnecter", role: .destructive) { authService.signOut() }
            }
        } header: {
            Text("Développement")
        } footer: {
            Text("python scripts/forge_dev_token.py")
                .font(.caption.monospaced())
        }
    }
    #endif

    // MARK: - Actions

    private func load() {
        let cal = Calendar.current
        if let p = profiles.first {
            firstName = p.firstName
            schoolLevel = p.schoolLevel.isEmpty ? "Lycée" : p.schoolLevel
        }
        eveTime  = cal.date(bySettingHour: storedEveHour,  minute: storedEveMinute,  second: 0, of: Date()) ?? Date()
        ddayTime = cal.date(bySettingHour: storedDdayHour, minute: storedDdayMinute, second: 0, of: Date()) ?? Date()
    }

    private func save() {
        let cal = Calendar.current
        storedEveHour   = cal.component(.hour,   from: eveTime)
        storedEveMinute = cal.component(.minute, from: eveTime)
        storedDdayHour   = cal.component(.hour,   from: ddayTime)
        storedDdayMinute = cal.component(.minute, from: ddayTime)

        let p: UserProfile
        if let existing = profiles.first { p = existing }
        else { p = UserProfile(); context.insert(p) }
        p.firstName = firstName.trimmingCharacters(in: .whitespaces)
        p.schoolLevel = schoolLevel
        dismiss()
    }

    private func loadQuota() {
        isLoadingQuota = true
        Task {
            do { quota = try await APIClient.shared.fetchQuota() } catch {}
            isLoadingQuota = false
        }
    }

    #if DEBUG
    private func applyDevToken() {
        let token = devToken.trimmingCharacters(in: .whitespaces)
        guard !token.isEmpty else { return }
        authService.setToken(token)
        devToken = ""
    }
    #endif
}
