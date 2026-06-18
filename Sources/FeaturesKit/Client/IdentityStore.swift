import Foundation

struct UserIdentity: Codable, Sendable {
    let displayName: String
    let email: String?
}

enum IdentityStore {
    private static let key = "com.featureskit.user-identity"

    static func load() -> UserIdentity? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let identity = try? JSONDecoder().decode(UserIdentity.self, from: data) else {
            return nil
        }
        return identity
    }

    static func save(_ identity: UserIdentity) {
        guard let data = try? JSONEncoder().encode(identity) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
