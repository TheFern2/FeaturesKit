import Foundation

public final class FeaturesClient: Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let userId: String?
    private let session: URLSession

    public init(apiKey: String, baseURL: String = "https://your-domain.com", userId: String? = nil) {
        self.apiKey = apiKey
        self.baseURL = URL(string: baseURL)!
        self.userId = userId
        self.session = .shared
    }

    // MARK: - Requests

    public func listRequests(
        sort: SortOrder = .votes,
        status: RequestStatus? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [FeatureRequest] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/requests"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        if let status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        components.queryItems = queryItems

        let request = makeRequest(url: components.url!)
        return try await perform(request)
    }

    public func getRequest(id: String) async throws -> FeatureRequestDetail {
        let url = baseURL.appendingPathComponent("/api/v1/requests/\(id)")
        let request = makeRequest(url: url)
        return try await perform(request)
    }

    public func createRequest(title: String, description: String?) async throws -> FeatureRequest {
        let url = baseURL.appendingPathComponent("/api/v1/requests")
        var body: [String: String] = ["title": title]
        if let description {
            body["description"] = description
        }
        let request = makeRequest(url: url, method: "POST", body: body)
        return try await perform(request)
    }

    // MARK: - Votes

    public func vote(requestId: String) async throws -> VoteResult {
        let url = baseURL.appendingPathComponent("/api/v1/requests/\(requestId)/vote")
        let request = makeRequest(url: url, method: "POST")
        return try await perform(request)
    }

    public func unvote(requestId: String) async throws -> VoteResult {
        let url = baseURL.appendingPathComponent("/api/v1/requests/\(requestId)/vote")
        let request = makeRequest(url: url, method: "DELETE")
        return try await perform(request)
    }

    // MARK: - Comments

    public func addComment(requestId: String, body: String) async throws -> Comment {
        let url = baseURL.appendingPathComponent("/api/v1/requests/\(requestId)/comments")
        let request = makeRequest(url: url, method: "POST", body: ["body": body])
        return try await perform(request)
    }

    // MARK: - Internal

    private func makeRequest(url: URL, method: String = "GET", body: [String: String]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(DeviceID.current, forHTTPHeaderField: "X-Device-ID")
        if let userId {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeaturesError.networkError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw FeaturesError.networkError(underlying: URLError(.badServerResponse))
        }

        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                message = apiError.error
            } else {
                message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }
            throw FeaturesError.apiError(status: http.statusCode, message: message)
        }

        do {
            return try JSONDecoder.features.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[FeaturesKit] Decoding \(T.self) failed: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("[FeaturesKit] Raw response: \(json)")
            }
            #endif
            throw FeaturesError.decodingError
        }
    }
}

extension JSONDecoder {
    static let features: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]
        let iso8601Frac = ISO8601DateFormatter()
        iso8601Frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = iso8601Frac.date(from: string) { return date }
            if let date = iso8601.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let features: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
