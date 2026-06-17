import Foundation

enum PendingAction: Codable {
    case vote(requestId: String)
    case unvote(requestId: String)
    case submit(title: String, description: String?)
}

enum PendingActionQueue {
    private static let key = "com.featureskit.pending-actions"

    static func enqueue(_ action: PendingAction) {
        var actions = load()
        actions.append(action)
        save(actions)
    }

    static func load() -> [PendingAction] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let actions = try? JSONDecoder().decode([PendingAction].self, from: data) else {
            return []
        }
        return actions
    }

    static func save(_ actions: [PendingAction]) {
        guard let data = try? JSONEncoder().encode(actions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
