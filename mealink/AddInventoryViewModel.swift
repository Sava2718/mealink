import Foundation
import Combine

@MainActor
final class AddInventoryViewModel: ObservableObject {
    @Published var rows: [InventoryInputRow] = [InventoryInputRow()]
    @Published var suggestions: [IngredientSuggestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: InventoryRepository?
    private var searchTask: Task<Void, Never>?

    init(repository: InventoryRepository? = nil) {
        if let repository {
            self.repository = repository
        } else {
            self.repository = SupabaseInventoryRepository()
        }
    }

    func updateSearch(for row: InventoryInputRow) {
        guard let repo = repository else { return }
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            do {
                let results = try await repo.searchIngredients(keyword: row.nameInput)
                await MainActor.run {
                    self?.suggestions = results
                }
            } catch {
                await MainActor.run { self?.errorMessage = error.localizedDescription }
            }
        }
    }

    func selectSuggestion(_ suggestion: IngredientSuggestion, for rowID: UUID) {
        if let idx = rows.firstIndex(where: { $0.id == rowID }) {
            rows[idx].selectedIngredient = suggestion
            rows[idx].nameInput = suggestion.name
            rows[idx].unitInput = suggestion.unit ?? rows[idx].unitInput
        }
        suggestions = []
    }

    func addRow() {
        rows.append(InventoryInputRow())
    }

    func removeRow(_ row: InventoryInputRow) {
        rows.removeAll { $0.id == row.id }
    }

    private func insertIfNeeded(row: InventoryInputRow, suggestion: IngredientSuggestion?) async throws -> IngredientSuggestion {
        guard let repo = repository else { throw NSError(domain: "repo", code: -1) }
        if let suggestion { return suggestion }
        return try await repo.insertUserIngredient(name: row.nameInput)
    }

    func submit() async {
        guard let repo = repository else {
            errorMessage = "Supabaseが利用できません"
            return
        }
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            var requests: [InventoryInsertRequest] = []
            for row in rows {
                let name = row.nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let selected = try await insertIfNeeded(row: row, suggestion: row.selectedIngredient)
                let quantity = Double(row.quantityInput) ?? 0
                let req = InventoryInsertRequest(
                    ingredientId: selected.id,
                    quantity: quantity,
                    unit: row.unitInput.isEmpty ? (selected.unit ?? "") : row.unitInput,
                    location: row.location,
                    expiresAt: row.expiresAt
                )
                requests.append(req)
            }
            try await repo.insertInventory(items: requests)
            successMessage = "登録が完了しました"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InventoryInputRow: Identifiable, Equatable {
    let id = UUID()
    var nameInput: String = ""
    var quantityInput: String = ""
    var unitInput: String = ""
    var location: String = "冷蔵"
    var expiresAt: String? = nil
    var selectedIngredient: IngredientSuggestion? = nil
}
