import Foundation

protocol DataProvider {
    func fetchRecipeSummary() async throws -> [DBRecipeSummaryRow]
    func fetchInventory() async throws -> [InventoryItem]
}

struct DBRecipeSummaryRow: Identifiable, Decodable {
    let recipe_id: UUID
    let recipe_name: String
    let cuisine: String?
    let cook_time: Int?
    let servings: Int?
    let photo_url: String?
    let shortage_items_count: Int
    let can_cook: Bool

    var id: UUID { recipe_id }

    enum CodingKeys: String, CodingKey {
        case recipe_id
        case recipe_name
        case cuisine
        case cook_time
        case servings
        case photo_url
        case shortage_items_count
        case can_cook
    }
}

/// Mock implementation to unblock UI until DB is wired.
final class MockDataProvider: DataProvider {
    func fetchRecipeSummary() async throws -> [DBRecipeSummaryRow] {
        [
            DBRecipeSummaryRow(
                recipe_id: UUID(),
                recipe_name: "鶏肉と野菜のパステルグリル",
                cuisine: "洋食",
                cook_time: 15,
                servings: 2,
                photo_url: nil,
                shortage_items_count: 1,
                can_cook: false
            )
        ]
    }

    func fetchInventory() async throws -> [InventoryItem] {
        [
            InventoryItem(name: "キャベツ", quantityLabel: "半玉", fill: 0.6, emoji: "🥬", category: "野菜"),
            InventoryItem(name: "トマト", quantityLabel: "3個", fill: 0.25, emoji: "🍅", category: "野菜", alert: true),
            InventoryItem(name: "にんじん", quantityLabel: "1本", fill: 0.4, emoji: "🥕", category: "野菜"),
            InventoryItem(name: "鶏むね肉", quantityLabel: "あと2日", fill: 0.75, emoji: "🍗", category: "肉・魚"),
        ]
    }
}

#if canImport(Supabase)
import Supabase

final class SupabaseDataProvider: DataProvider {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchRecipeSummary() async throws -> [DBRecipeSummaryRow] {
        let response = try await client
            .rpc("rpc_recipe_summary")
            .execute()

        let raw = String(data: response.data ?? Data(), encoding: .utf8)
        if let raw { print("[RecipeSummary] raw json:", raw) }

        do {
            let rows: [DBRecipeSummaryRow] = try decodeResponse(data: response.data)
            print("[RecipeSummary] count:", rows.count)
            return rows
        } catch {
            if let raw { print("[RecipeSummary] decode error raw:", raw) }
            throw error
        }
    }

    func fetchInventory() async throws -> [InventoryItem] {
        let query = """
id,
user_id,
ingredient_id,
quantity,
unit,
expires_at,
updated_at,
ingredients:ingredient_id(
  name,
  category,
  unit
)
"""
        let response = try await client
            .from("inventory")
            .select(query)
            .execute()
        let rows: [InventoryRow] = try decodeResponse(data: response.data)
        return rows.map { $0.toDomain() }
    }
}

private struct InventoryRow: Decodable {
    let id: UUID?
    let user_id: UUID?
    let ingredient_id: UUID?
    let quantity: Double?
    let unit: String?
    let expires_at: String?
    let updated_at: String?
    let ingredients: IngredientRow?

    func toDomain() -> InventoryItem {
        let qtyLabel: String
        if let quantity, let unit, !unit.isEmpty {
            qtyLabel = "\(quantity)\(unit)"
        } else if let quantity {
            qtyLabel = "\(quantity)"
        } else {
            qtyLabel = unit ?? ""
        }
        let fill = min(max((quantity ?? 0) / 5.0, 0), 1) // placeholder gauge

        return InventoryItem(
            id: id ?? UUID(),
            name: ingredients?.name ?? "食材ID: \(ingredient_id?.uuidString.prefix(8) ?? "unknown")",
            quantityLabel: qtyLabel,
            fill: fill,
            emoji: emojiFor(category: ingredients?.category ?? "その他"),
            category: ingredients?.category ?? "その他",
            alert: false,
            expiresAt: expires_at,
            location: nil
        )
    }
}

private struct IngredientRow: Decodable {
    let name: String?
    let category: String?
    let unit: String?
}

// MARK: - Decode helper

private func decodeResponse<T: Decodable>(data: Data?) throws -> T {
    let decoder = JSONDecoder()
    guard let data else {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty response"))
    }
    return try decoder.decode(T.self, from: data)
}

private func emojiFor(category: String) -> String {
    if category.contains("肉") { return "🍗" }
    if category.contains("魚") { return "🐟" }
    if category.contains("野菜") { return "🥕" }
    if category.contains("果") { return "🍎" }
    return "🥫"
}
#endif
