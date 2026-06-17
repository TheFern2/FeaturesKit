import Foundation

enum DeviceID {
    private static let key = "com.featureskit.device-id"

    nonisolated(unsafe) private static var cached: String?

    static var current: String {
        if let cached { return cached }

        if let existing = UserDefaults.standard.string(forKey: key) {
            cached = existing
            return existing
        }

        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        cached = id
        return id
    }
}
