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

    init?(client: SupabaseClient? = SupabaseClients.shared.client) {
        guard let client else { return nil }
        self.client = client
    }

func searchIngredients(keyword: String) async throws -> [IngredientSuggestion] {
    let raw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !raw.isEmpty else { return [] }

    // ログイン済みユーザーの uid（匿名ログインなし）
    let uid = try requireSessionUserId()

    // ひらがな前提の normalized 用（最低限 lowercase）
    let norm = raw.lowercased()

    let response = try await client
        .from("ingredients")
        .select("id,name,category,unit,scope,status,owner_user_id,normalized_name")
        // 漢字入力救済：name側も部分一致で拾う
        .or("normalized_name.ilike.\(norm)%,name.ilike.%\(raw)%")
        // master(active) と user(自分の分) のみに限定
        .or("and(scope.eq.master,status.eq.active),and(scope.eq.user,owner_user_id.eq.\(uid.uuidString),status.in.(active,pending))")
        .limit(10)
        .execute()

    let rows: [IngredientRow] = try decodeResponse(data: response.data)
    return rows.map { $0.toSuggestion() }
}


    func insertUserIngredient(name: String) async throws -> IngredientSuggestion {
        // 確実に user_id を取得（ログイン必須）
        let uid = try requireSessionUserId()
        // まず重複チェック（同一ユーザー & scope=user & normalized_name一致）
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dupResponse = try await client
            .from("ingredients")
            .select("id,name,category,unit,scope,status,owner_user_id,normalized_name")
            .eq("scope", value: "user")
            .eq("owner_user_id", value: uid.uuidString) // クエリ条件は文字列で渡す必要がある
            .eq("normalized_name", value: normalized)
            .limit(1)
            .execute()

        let existing: [IngredientRow] = try decodeResponse(data: dupResponse.data)
        if let first = existing.first {
            return first.toSuggestion()
        }


        let payload = UserIngredientInsert(
            name: name,
            normalized_name: normalized,
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
        let uid = try requireSessionUserId()
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

    /// ログイン必須（Magic Link 前提）。未ログインなら明示的にエラーを返す。
    fileprivate func requireSessionUserId() throws -> UUID {
        guard let uid = client.auth.currentSession?.user.id else {
            throw AuthRequiredError()
        }
        return uid
    }
}

struct AuthRequiredError: LocalizedError {
    var errorDescription: String? { "ログインが必要です" }
}

private struct IngredientRow: Decodable {
    let id: UUID
    let name: String
    let category: String?
    let unit: String?
    let scope: String?
    let status: String?
    let owner_user_id: UUID?
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
    let owner_user_id: UUID
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
