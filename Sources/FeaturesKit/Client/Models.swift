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

    public init(
        id: String, title: String, description: String?, status: RequestStatus,
        visibility: RequestVisibility, voteCount: Int, commentCount: Int, voted: Bool,
        deviceId: String, createdAt: Date, updatedAt: Date
    ) {
        self.id = id; self.title = title; self.description = description; self.status = status
        self.visibility = visibility; self.voteCount = voteCount; self.commentCount = commentCount
        self.voted = voted; self.deviceId = deviceId; self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decode(RequestStatus.self, forKey: .status)
        visibility = try container.decode(RequestVisibility.self, forKey: .visibility)
        voteCount = try container.decode(Int.self, forKey: .voteCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        voted = try container.decodeIfPresent(Bool.self, forKey: .voted) ?? false
        deviceId = try container.decode(String.self, forKey: .deviceId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
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
