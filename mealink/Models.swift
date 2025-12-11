import Foundation

struct Recipe: Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let cookTimeMin: Int?
    let servings: Int?
    let ingredients: [RecipeIngredient]
    let imageURL: URL?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        cookTimeMin: Int? = nil,
        servings: Int? = nil,
        ingredients: [RecipeIngredient] = [],
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.cookTimeMin = cookTimeMin
        self.servings = servings
        self.ingredients = ingredients
        self.imageURL = imageURL
    }
}

struct RecipeIngredient: Identifiable {
    let id: UUID
    let name: String
    let amount: String
    let isAlert: Bool

    init(id: UUID = UUID(), name: String, amount: String, isAlert: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isAlert = isAlert
    }
}

struct InventoryItem: Identifiable {
    let id: UUID
    let name: String
    let quantityLabel: String
    let fill: Double
    let emoji: String
    let category: String
    let alert: Bool
    let expiresAt: String?
    let location: String?

    init(
        id: UUID = UUID(),
        name: String,
        quantityLabel: String,
        fill: Double,
        emoji: String,
        category: String,
        alert: Bool = false,
        expiresAt: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantityLabel = quantityLabel
        self.fill = fill
        self.emoji = emoji
        self.category = category
        self.alert = alert
        self.expiresAt = expiresAt
        self.location = location
    }
}

struct MealLog: Identifiable {
    let id: UUID
    let time: String
    let menu: String
    let icon: String

    init(id: UUID = UUID(), time: String, menu: String, icon: String) {
        self.id = id
        self.time = time
        self.menu = menu
        self.icon = icon
    }
}
