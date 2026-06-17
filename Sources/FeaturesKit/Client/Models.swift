import Foundation

public struct FeatureRequest: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let status: RequestStatus
    public let visibility: RequestVisibility
    public let voteCount: Int
    public let commentCount: Int
    public let voted: Bool
    public let deviceId: String
    public let createdAt: Date
    public let updatedAt: Date
}

public struct FeatureRequestDetail: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let status: RequestStatus
    public let visibility: RequestVisibility
    public let voteCount: Int
    public let commentCount: Int
    public let voted: Bool
    public let deviceId: String
    public let userId: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let comments: [Comment]
}

public struct Comment: Codable, Identifiable, Sendable {
    public let id: String
    public let body: String
    public let deviceId: String
    public let userId: String?
    public let isDeveloper: Bool
    public let createdAt: Date
}

public struct VoteResult: Codable, Sendable {
    public let voted: Bool
}

public enum RequestStatus: String, Codable, CaseIterable, Sendable {
    case new
    case underReview = "under_review"
    case planned
    case inProgress = "in_progress"
    case shipped
    case declined
}

public enum RequestVisibility: String, Codable, Sendable {
    case pending
    case approved
    case rejected
}

public enum SortOrder: String, Sendable {
    case votes
    case newest
    case oldest
}

public enum FeaturesError: Error, LocalizedError, Sendable {
    case networkError(underlying: any Error)
    case apiError(status: Int, message: String)
    case decodingError

    public var errorDescription: String? {
        switch self {
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .apiError(_, let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

extension FeatureRequest {
    func withVote(_ voted: Bool, count: Int) -> FeatureRequest {
        FeatureRequest(
            id: id,
            title: title,
            description: description,
            status: status,
            visibility: visibility,
            voteCount: count,
            commentCount: commentCount,
            voted: voted,
            deviceId: deviceId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct APIErrorResponse: Codable {
    let error: String
}
