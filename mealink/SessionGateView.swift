import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct SessionGateView: View {
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
        .task {
            await refreshSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
            Task { await refreshSession() }
        }
    }

    private func refreshSession() async {
#if canImport(Supabase)
        if let client = SupabaseClients.shared.client, client.auth.currentSession != nil {
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
#else
        isLoggedIn = false
#endif
    }
}

extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}
