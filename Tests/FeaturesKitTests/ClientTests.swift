import Foundation
import Testing
@testable import FeaturesKit

@Suite("Models")
struct ModelsTests {
    @Test func decodeFeatureRequest() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Dark mode",
            "description": "Add dark mode support",
            "status": "planned",
            "visibility": "approved",
            "vote_count": 5,
            "comment_count": 2,
            "voted": true,
            "device_id": "device-1",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let request = try JSONDecoder.features.decode(FeatureRequest.self, from: json)
        #expect(request.id == "abc-123")
        #expect(request.title == "Dark mode")
        #expect(request.description == "Add dark mode support")
        #expect(request.status == .planned)
        #expect(request.visibility == .approved)
        #expect(request.voteCount == 5)
        #expect(request.commentCount == 2)
        #expect(request.voted == true)
        #expect(request.deviceId == "device-1")
    }

    @Test func decodeFeatureRequestDetail() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Dark mode",
            "description": null,
            "status": "new",
            "visibility": "pending",
            "vote_count": 0,
            "comment_count": 1,
            "voted": false,
            "device_id": "device-1",
            "user_id": "user-1",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "comments": [
                {
                    "id": "comment-1",
                    "body": "Great idea",
                    "device_id": "device-2",
                    "user_id": null,
                    "is_developer": false,
                    "created_at": "2026-01-01T12:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder.features.decode(FeatureRequestDetail.self, from: json)
        #expect(detail.id == "abc-123")
        #expect(detail.description == nil)
        #expect(detail.userId == "user-1")
        #expect(detail.comments.count == 1)
        #expect(detail.comments[0].body == "Great idea")
        #expect(detail.comments[0].isDeveloper == false)
    }

    @Test func decodeVoteResult() throws {
        let json = """
        {"voted": true}
        """.data(using: .utf8)!

        let result = try JSONDecoder.features.decode(VoteResult.self, from: json)
        #expect(result.voted == true)
    }

    @Test func requestStatusRawValues() {
        #expect(RequestStatus.underReview.rawValue == "under_review")
        #expect(RequestStatus.inProgress.rawValue == "in_progress")
        #expect(RequestStatus.new.rawValue == "new")
        #expect(RequestStatus.shipped.rawValue == "shipped")
    }

    @Test func sortOrderRawValues() {
        #expect(SortOrder.votes.rawValue == "votes")
        #expect(SortOrder.newest.rawValue == "newest")
        #expect(SortOrder.oldest.rawValue == "oldest")
    }
}

@Suite("FeaturesError")
struct FeaturesErrorTests {
    @Test func apiErrorDescription() {
        let error = FeaturesError.apiError(status: 404, message: "Request not found")
        #expect(error.errorDescription == "Request not found")
    }

    @Test func decodingErrorDescription() {
        let error = FeaturesError.decodingError
        #expect(error.errorDescription == "Failed to decode response")
    }
}
