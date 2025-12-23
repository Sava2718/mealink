import Foundation
#if canImport(Supabase)
import Supabase
#endif

enum AuthError: Error {
    case clientUnavailable
    case unsupported
}

final class AuthService {
#if canImport(Supabase)
    private let client: SupabaseClient?

    init(client: SupabaseClient? = SupabaseClients.shared.client) {
        self.client = client
    }

    /// Magic Link をメールに送信する（onOpenURLは別ステップで処理）
    func sendMagicLink(email: String) async throws {
        guard let client else { throw AuthError.clientUnavailable }
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "mealink://login-callback")
        )
    }

    /// ログアウト（セッション破棄）
    func logout() async throws {
        guard let client else { throw AuthError.clientUnavailable }
        try await client.auth.signOut()
        NotificationCenter.default.post(name: .authStateDidChange, object: nil)
    }
#else
    private let client: Any? = nil
    init() {}
    func sendMagicLink(email: String) async throws { throw AuthError.unsupported }
    func logout() async throws { throw AuthError.unsupported }
#endif
}
