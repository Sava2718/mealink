import Foundation

protocol InventoryRepository {
    func searchIngredients(keyword: String) async throws -> [IngredientSuggestion]
    func insertUserIngredient(name: String) async throws -> IngredientSuggestion
    func insertInventory(items: [InventoryInsertRequest]) async throws
}

struct IngredientSuggestion: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String?
    let unit: String?
}

struct InventoryInsertRequest: Identifiable {
    let id = UUID()
    let ingredientId: UUID
    let quantity: Double
    let unit: String
    let location: String
    let expiresAt: String?
    let inventoryId: UUID = UUID()
}

#if canImport(Supabase)
import Supabase

final class SupabaseInventoryRepository: InventoryRepository {
    private let client: SupabaseClient
    private let deviceId: UUID = LocalUserIDProvider.deviceUUID

    init?(client: SupabaseClient? = SupabaseClients.shared.client) {
        guard let client else { return nil }
        self.client = client
    }

    func searchIngredients(keyword: String) async throws -> [IngredientSuggestion] {
        let norm = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !norm.isEmpty else { return [] }
        let uid = deviceId.uuidString
        let response = try await client
            .from("ingredients")
            .select("id,name,category,unit,scope,status,owner_user_id,normalized_name")
            .ilike("normalized_name", pattern: "%\(norm)%")
            .or("and(scope.eq.master,status.eq.active),and(scope.eq.user,owner_user_id.eq.\(uid),status.in.(active,pending))")
            .limit(10)
            .execute()
        let rows: [IngredientRow] = try decodeResponse(data: response.data)
        return rows.map { $0.toSuggestion() }
    }

    func insertUserIngredient(name: String) async throws -> IngredientSuggestion {
        let uid = deviceId.uuidString
        let payload = UserIngredientInsert(
            name: name,
            normalized_name: name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            scope: "user",
            status: "pending",
            owner_user_id: uid
        )
        let response = try await client
            .from("ingredients")
            .insert(payload, returning: .representation)
            .single()
            .execute()
        let row: IngredientRow = try decodeResponse(data: response.data)
        return row.toSuggestion()
    }

    func insertInventory(items: [InventoryInsertRequest]) async throws {
        guard !items.isEmpty else { return }
        let uid = try await ensureAnonymousSession()
        let payloads = items.map {
            InventoryInsertRow(
                id: $0.inventoryId,
                ingredient_id: $0.ingredientId,
                quantity: $0.quantity,
                unit: $0.unit,
                expires_at: $0.expiresAt,
                location: $0.location,
                user_id: uid
            )
        }
        _ = try await client
            .from("inventory")
            .insert(payloads, returning: .minimal)
            .execute()
    }

    /// Ensure session exists; sign in anonymously otherwise.
    private func ensureAnonymousSession() async throws -> UUID {
        if let uid = client.auth.currentSession?.user.id {
            return uid
        }
        let session = try await client.auth.signInAnonymously()
        return session.user.id
    }
}

private struct IngredientRow: Decodable {
    let id: UUID
    let name: String
    let category: String?
    let unit: String?
    let scope: String?
    let status: String?
    let owner_user_id: String?
    let normalized_name: String?

    func toSuggestion() -> IngredientSuggestion {
        IngredientSuggestion(id: id, name: name, category: category, unit: unit)
    }
}

private struct UserIngredientInsert: Encodable {
    let name: String
    let normalized_name: String
    let scope: String
    let status: String
    let owner_user_id: String
}

private struct InventoryInsertRow: Encodable {
    let id: UUID
    let ingredient_id: UUID
    let quantity: Double
    let unit: String
    let expires_at: String?
    let location: String
    let user_id: UUID
}

private func decodeResponse<T: Decodable>(data: Data?) throws -> T {
    let decoder = JSONDecoder()
    guard let data else {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty response"))
    }
    return try decoder.decode(T.self, from: data)
}
#endif
