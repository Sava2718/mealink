import Foundation

enum LocalUserIDProvider {
    private static let key = "mealink_local_user_id"

    static var deviceUUID: UUID {
        if let stored = UserDefaults.standard.string(forKey: key), let uuid = UUID(uuidString: stored) {
            return uuid
        }
        let new = UUID()
        UserDefaults.standard.set(new.uuidString, forKey: key)
        return new
    }
}
