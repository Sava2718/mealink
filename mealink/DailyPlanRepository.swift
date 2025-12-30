import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct DailyPlan: Decodable {
    let id: UUID
    let user_id: UUID
    let plan_date: String
    let meal_slot: String
    let planned_recipe_id: UUID?
    let status: String?
}

#if canImport(Supabase)
final class DailyPlanRepository {
    private let client: SupabaseClient

    init?(client: SupabaseClient? = SupabaseClients.shared.client) {
        guard let client else { return nil }
        self.client = client
    }

    /// 今日(JST)の日付文字列を返す (YYYY-MM-DD)
    func todayDateString() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let comps = calendar.dateComponents([.year, .month, .day], from: Date())
        let date = calendar.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func fetchTodayDinnerPlan() async throws -> DailyPlan? {
        let uid = try requireUserId()
        let planDate = todayDateString()
        let response = try await client
            .from("daily_plans")
            .select("*")
            .eq("user_id", value: uid.uuidString)
            .eq("plan_date", value: planDate)
            .eq("meal_slot", value: "dinner")
            .limit(1)
            .execute()

        if let raw = String(data: response.data ?? Data(), encoding: .utf8) {
            print("[DailyPlan fetch] raw:", raw)
        }
        // maybeSingle が無いSDKのため配列デコード→firstで対応
        let rows: [DailyPlan] = try decodeResponse(data: response.data) ?? []
        return rows.first
    }

    func upsertTodayDinner(planRecipeId: UUID?) async throws {
        let uid = try requireUserId()
        let planDate = todayDateString()
        struct Payload: Encodable {
            let user_id: UUID
            let plan_date: String
            let meal_slot: String
            let planned_recipe_id: UUID?
        }
        let payload = Payload(
            user_id: uid,
            plan_date: planDate,
            meal_slot: "dinner",
            planned_recipe_id: planRecipeId
        )
        _ = try await client
            .from("daily_plans")
            .upsert(payload, onConflict: "user_id,plan_date,meal_slot", returning: .minimal)
            .execute()
    }

    private func requireUserId() throws -> UUID {
        guard let uid = client.auth.currentSession?.user.id else {
            throw AuthRequiredError()
        }
        return uid
    }
}

private func decodeResponse<T: Decodable>(data: Data?) throws -> T? {
    guard let data, !data.isEmpty else { return nil }
    return try JSONDecoder().decode(T.self, from: data)
}

#endif
