import Foundation

#if canImport(Supabase)
import Supabase

struct SupabaseClients {
    static let shared = SupabaseClients()
    let moduleAvailable = true

    let client: SupabaseClient?
    let isConfigured: Bool

    init() {
        guard
            let urlString = SupabaseSecrets.urlString,
            let url = URL(string: urlString),
            let anonKey = SupabaseSecrets.anonKey,
            !anonKey.isEmpty
        else {
#if DEBUG
            print("[Supabase] not configured (missing URL or anonKey)")
#endif
            client = nil
            isConfigured = false
            return
        }
#if DEBUG
        print("[Supabase] using url=\(urlString), anonKey.isEmpty=\(anonKey.isEmpty)")
#endif
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        isConfigured = true
    }
}

enum SupabaseProviderFactory {
    static func make() -> (any DataProvider)? {
        guard SupabaseClients.shared.isConfigured, let client = SupabaseClients.shared.client else {
            return nil
        }
        return SupabaseDataProvider(client: client)
    }
}
#else
// Supabase SDKがない場合でもビルドが通るダミー
struct SupabaseClients {
    static let shared = SupabaseClients()
    let moduleAvailable = false
    let client: Any? = nil
    let isConfigured = false
}

enum SupabaseProviderFactory {
    static func make() -> (any DataProvider)? { nil }
}
#endif
