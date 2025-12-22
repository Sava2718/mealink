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
                        Task { await viewModel.sendLink() }
                    } label: {
                        HStack {
                            if viewModel.isLoading { ProgressView() }
                            Text("ログインリンクを送信")
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
    @Published var isLoading = false
    @Published var infoMessage: String?
    @Published var errorMessage: String?
    private let service = AuthService()

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func sendLink() async {
        infoMessage = nil
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.sendMagicLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            infoMessage = "ログインリンクを送信しました。メールを確認してください。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
