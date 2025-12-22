import SwiftUI
import Combine

/// シンプルなメール登録/ログイン画面（バックエンド接続は後続で実装）
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("メールアドレス")) {
                    TextField("email@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("パスワード")) {
                    SecureField("パスワード", text: $viewModel.password)
                }

                if let message = viewModel.infoMessage {
                    Section {
                        Text(message)
                            .foregroundColor(.green)
                    }
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.register() }
                    } label: {
                        HStack {
                            if viewModel.isLoading { ProgressView() }
                            Text("登録する")
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        HStack {
                            if viewModel.isLoading { ProgressView() }
                            Text("ログイン")
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                }
            }
            .navigationTitle("メール登録 / ログイン")
        }
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var infoMessage: String?
    @Published var errorMessage: String?

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    // TODO: 後続で Supabase Auth を接続する
    func register() async {
        infoMessage = nil
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        // 実際のバックエンド接続は別途実装。ここではプレースホルダー。
        infoMessage = "登録リクエストを送信（実装予定）: \(email)"
    }

    func login() async {
        infoMessage = nil
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        // 実際のバックエンド接続は別途実装。ここではプレースホルダー。
        infoMessage = "ログインリクエストを送信（実装予定）: \(email)"
    }
}
