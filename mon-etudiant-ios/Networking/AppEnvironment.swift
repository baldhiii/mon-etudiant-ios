import Foundation

enum AppEnvironment {
    static var baseURL: URL {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: raw) { return url }
        return URL(string: "http://localhost:8000")!
        #else
        return URL(string: "https://mon-etudiant.onrender.com")!
        #endif
    }
}
