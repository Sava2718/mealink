import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showAuth {
                    AuthView()
                } else {
                    HealthLogView()
                }
            }
            .navigationTitle("マイページ")
            .toolbar {
                if !viewModel.showAuth {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "line.3.horizontal.circle")
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: MyPageSettingsView(viewModel: viewModel),
                    isActive: $showSettings
                ) { EmptyView() }
                .hidden()
            )
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
    private let authService = AuthService()

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
        do {
            try await authService.logout()
        } catch {
            // UIには大きく影響しないため、ここではエラーを握りつぶす
        }
        showAuth = true
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

/// これまでのマイページ設定リストを右上メニューからプッシュ表示するビュー
struct MyPageSettingsView: View {
    @ObservedObject var viewModel: MyPageViewModel

    var body: some View {
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
        .navigationTitle("設定")
    }
}
