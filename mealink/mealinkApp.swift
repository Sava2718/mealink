//
//  mealinkApp.swift
//  mealink
//
//  Created by Tya NaWa on 2025/12/11.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

@main
struct mealinkApp: App {
    var body: some Scene {
        WindowGroup {
            SessionGateView()
                .onOpenURL { url in
#if canImport(Supabase)
                    print("[Auth] onOpenURL:", url.absoluteString)
                    Task {
                        do {
                            if let client = SupabaseClients.shared.client {
                                try await client.auth.handle(url)
                                let uid = client.auth.currentSession?.user.id
                                print("[Auth] session user id:", uid?.uuidString ?? "nil")
                                NotificationCenter.default.post(name: .authStateDidChange, object: nil)
                            } else {
                                print("[Auth] Supabase client not available")
                            }
                        } catch {
                            print("[Auth] handle URL error:", error.localizedDescription)
                        }
                    }
#endif
                }

        }
    }
}
