import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct SessionGateView: View {
    @State private var isLoggedIn = false
    #if canImport(Supabase)
    @State private var authListenerTask: Task<Void, Never>?
    #endif

    var body: some View {
        Group {
            if isLoggedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
        .id(isLoggedIn) // 強制的にViewをリビルドしてスタックをリセット
        .task {
            await refreshSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
            Task { await refreshSession() }
        }
        .onAppear { startAuthListener() }
        .onDisappear { stopAuthListener() }
    }

    @MainActor
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

    private func startAuthListener() {
#if canImport(Supabase)
        guard authListenerTask == nil, let client = SupabaseClients.shared.client else { return }
        authListenerTask = Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    isLoggedIn = (state.session != nil)
                }
            }
        }
#endif
    }

    private func stopAuthListener() {
#if canImport(Supabase)
        authListenerTask?.cancel()
        authListenerTask = nil
#endif
    }
}

extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}
