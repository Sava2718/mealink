import Foundation

protocol DataProvider {
    func fetchRecipes() async throws -> [Recipe]
    func fetchInventory() async throws -> [InventoryItem]
}

/// Mock implementation to unblock UI until DB is wired.
final class MockDataProvider: DataProvider {
    func fetchRecipes() async throws -> [Recipe] {
        [
            Recipe(
                title: "鶏肉と野菜のパステルグリル",
                description: "彩り野菜と鶏肉をオーブンでじっくり焼いた一品。",
                cookTimeMin: 15,
                servings: 2,
                ingredients: [
                    RecipeIngredient(name: "鶏肉", amount: "200g"),
                    RecipeIngredient(name: "ズッキーニ", amount: "1本 不足", isAlert: true),
                    RecipeIngredient(name: "パプリカ", amount: "1/2個"),
                    RecipeIngredient(name: "ピーマン", amount: "1個"),
                ],
                imageURL: nil
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

    func fetchRecipes() async throws -> [Recipe] {
        let query = """
id,
title,
description,
cook_time_min,
servings,
created_at
"""
        let response = try await client
            .from("recipes")
            .select(query)
            .execute()
        let rows: [RecipeRow] = try decodeResponse(data: response.data)
        return rows.map { $0.toDomain() }
    }

    func fetchInventory() async throws -> [InventoryItem] {
        let query = """
id,
user_id,
ingredient_id,
quantity,
unit,
expires_at,
updated_at
"""
        let response = try await client
            .from("inventory")
            .select(query)
            .execute()
        let rows: [InventoryRow] = try decodeResponse(data: response.data)
        return rows.map { $0.toDomain() }
    }
}

private struct RecipeRow: Decodable {
    let id: UUID?
    let title: String
    let description: String?
    let cook_time_min: Int?
    let servings: Int?
    let created_at: String?

    func toDomain() -> Recipe {
        Recipe(
            id: id ?? UUID(),
            title: title,
            description: description,
            cookTimeMin: cook_time_min,
            servings: servings,
            ingredients: [] // ingredients will be filled later when schema available
        )
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
            name: "食材ID: \(ingredient_id?.uuidString.prefix(8) ?? "unknown")",
            quantityLabel: qtyLabel,
            fill: fill,
            emoji: "🥫",
            category: "その他",
            alert: false,
            expiresAt: expires_at,
            location: nil
        )
    }
}

// MARK: - Decode helper

private func decodeResponse<T: Decodable>(data: Data?) throws -> T {
    let decoder = JSONDecoder()
    guard let data else {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty response"))
    }
    return try decoder.decode(T.self, from: data)
}
#endif
