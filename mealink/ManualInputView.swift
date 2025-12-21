import SwiftUI
import Combine

/// 手入力で在庫登録する画面（Supabase連携版）
struct ManualInputView: View {
    @StateObject private var viewModel = ManualInputViewModel()

    var body: some View {
        Form {
            Section(header: Text("食材情報")) {
                TextField("食材名", text: $viewModel.name)
                TextField("数量 (例: 2)", text: $viewModel.quantity)
                    .keyboardType(.decimalPad)
                TextField("単位 (例: 個, g)", text: $viewModel.unit)
                Picker("保管場所", selection: $viewModel.location) {
                    ForEach(["冷蔵", "冷凍", "常温"], id: \.self) { Text($0) }
                }
                TextField("賞味期限 (任意 YYYY-MM-DD)", text: Binding(
                    get: { viewModel.expires ?? "" },
                    set: { viewModel.expires = $0.isEmpty ? nil : $0 }
                ))
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundColor(.red) }
            }
            if let success = viewModel.successMessage {
                Section { Text(success).foregroundColor(.green) }
            }

            Section {
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView() }
                        Text("この内容で登録する")
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("手入力で追加")
    }
}

@MainActor
final class ManualInputViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var quantity: String = ""
    @Published var unit: String = ""
    @Published var location: String = "冷蔵"
    @Published var expires: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: InventoryRepository? = SupabaseInventoryRepository()

    func submit() async {
        errorMessage = nil
        successMessage = nil
        guard let repo = repository else {
            errorMessage = "Supabaseが利用できません"
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "食材名を入力してください"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let candidates = try await repo.searchIngredients(keyword: trimmedName)
            let matched = candidates.first { $0.name.lowercased() == trimmedName.lowercased() }
            let ingredient: IngredientSuggestion
            if let matched {
                ingredient = matched
            } else {
                ingredient = try await repo.insertUserIngredient(name: trimmedName)
            }

            let qty = Double(quantity) ?? 0
            let req = InventoryInsertRequest(
                ingredientId: ingredient.id,
                quantity: qty,
                unit: unit.isEmpty ? (ingredient.unit ?? "") : unit,
                location: location,
                expiresAt: expires
            )
            try await repo.insertInventory(items: [req])
            successMessage = "登録が完了しました"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
