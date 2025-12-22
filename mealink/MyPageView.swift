import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showAuth {
                    AuthView()
                } else {
                    List {
                        Section {
                            HStack {
                                Circle().fill(Color(hex: "#BCEFD6")).frame(width: 48, height: 48)
                                    .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                                VStack(alignment: .leading) {
                                    Text(viewModel.displayName).font(.headline)
                                    Text("匿名ではありません").font(.subheadline).foregroundStyle(.gray)
                                }
                            }
                        }
                        Section {
                            Label("通知設定", systemImage: "bell")
                            Label("プライバシー設定", systemImage: "lock")
                            Button(role: .destructive) {
                                Task { await viewModel.logout() }
                            } label: {
                                Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.forward")
                            }
                        }
                    }
                }
            }
            .navigationTitle("マイページ")
            .task {
                await viewModel.refresh()
            }
        }
    }
}

@MainActor
final class MyPageViewModel: ObservableObject {
    @Published var showAuth: Bool = true
    @Published var displayName: String = "ユーザー"

    func refresh() async {
#if canImport(Supabase)
        guard let client = SupabaseClients.shared.client else {
            showAuth = true
            return
        }
        if let session = client.auth.currentSession {
            let user = session.user
            let provider = providerName(from: user)
            if provider == "anonymous" {
                showAuth = true
            } else {
                showAuth = false
                displayName = user.email ?? "ログイン中ユーザー"
            }
        } else {
            showAuth = true
        }
#else
        showAuth = true
#endif
    }

    func logout() async {
#if canImport(Supabase)
        do {
            try await SupabaseClients.shared.client?.auth.signOut()
        } catch {
            // ignore logout errors for now
        }
        showAuth = true
#else
        showAuth = true
#endif
    }

#if canImport(Supabase)
    private func providerName(from user: User) -> String? {
        if let any = user.appMetadata["provider"]?.value {
            return any as? String ?? "\(any)"
        }
        return nil
    }
#endif
}
