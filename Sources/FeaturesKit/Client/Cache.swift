import Foundation

enum RequestCache {
    private static let key = "com.featureskit.cached-requests"

    static func save(_ requests: [FeatureRequest]) {
        guard let data = try? JSONEncoder.features.encode(requests) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> [FeatureRequest]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let requests = try? JSONDecoder.features.decode([FeatureRequest].self, from: data) else {
            return nil
        }
        return requests
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
