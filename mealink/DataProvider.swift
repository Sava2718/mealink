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
