import Foundation

extension FeatureRequest {
    static let preview = FeatureRequest(
        id: "preview-1",
        title: "Dark mode support",
        description: "Add a system-wide dark mode toggle that remembers user preference across sessions.",
        status: .planned,
        visibility: .approved,
        voteCount: 24,
        commentCount: 3,
        voted: false,
        deviceId: "device-abc",
        createdAt: Date(timeIntervalSinceNow: -86400 * 3),
        updatedAt: Date(timeIntervalSinceNow: -86400)
    )

    static let previewList: [FeatureRequest] = [
        .preview,
        FeatureRequest(
            id: "preview-2",
            title: "Export to PDF",
            description: "Let me export reports as PDF files for sharing with the team.",
            status: .new,
            visibility: .approved,
            voteCount: 18,
            commentCount: 1,
            voted: true,
            deviceId: "device-def",
            createdAt: Date(timeIntervalSinceNow: -86400 * 5),
            updatedAt: Date(timeIntervalSinceNow: -86400 * 2)
        ),
        FeatureRequest(
            id: "preview-3",
            title: "Keyboard shortcuts",
            description: "Add vim-style navigation shortcuts for power users.",
            status: .shipped,
            visibility: .approved,
            voteCount: 12,
            commentCount: 0,
            voted: false,
            deviceId: "device-ghi",
            createdAt: Date(timeIntervalSinceNow: -86400 * 10),
            updatedAt: Date(timeIntervalSinceNow: -86400 * 1)
        ),
        FeatureRequest(
            id: "preview-4",
            title: "Offline mode",
            description: nil,
            status: .inProgress,
            visibility: .approved,
            voteCount: 9,
            commentCount: 2,
            voted: false,
            deviceId: "device-jkl",
            createdAt: Date(timeIntervalSinceNow: -86400 * 7),
            updatedAt: Date(timeIntervalSinceNow: -86400 * 1)
        ),
    ]
}

extension Comment {
    static let previewList: [Comment] = [
        Comment(
            id: "comment-1",
            body: "Would love this for OLED screens",
            deviceId: "device-abc",
            userId: nil,
            displayName: "Alex",
            email: nil,
            isDeveloper: false,
            createdAt: Date(timeIntervalSinceNow: -86400 * 2)
        ),
        Comment(
            id: "comment-2",
            body: "Good idea, adding to the backlog",
            deviceId: "device-dev",
            userId: "admin",
            displayName: nil,
            email: nil,
            isDeveloper: true,
            createdAt: Date(timeIntervalSinceNow: -86400)
        ),
        Comment(
            id: "comment-3",
            body: "+1, dark mode is a must for late night usage",
            deviceId: "device-xyz",
            userId: nil,
            displayName: "Jordan",
            email: "jordan@example.com",
            isDeveloper: false,
            createdAt: Date(timeIntervalSinceNow: -3600)
        ),
    ]
}

extension FeatureRequestDetail {
    static let preview = FeatureRequestDetail(
        id: "preview-1",
        title: "Dark mode support",
        description: "Add a system-wide dark mode toggle that remembers user preference across sessions. Should respect the system setting by default but allow override.",
        status: .planned,
        visibility: .approved,
        voteCount: 24,
        commentCount: 3,
        voted: false,
        deviceId: "device-abc",
        userId: nil,
        displayName: "Alex",
        email: nil,
        createdAt: Date(timeIntervalSinceNow: -86400 * 3),
        updatedAt: Date(timeIntervalSinceNow: -86400),
        comments: Comment.previewList
    )
}

extension FeaturesViewModel {
    static var preview: FeaturesViewModel {
        let client = FeaturesClient(apiKey: "preview", baseURL: "http://invalid")
        let vm = FeaturesViewModel(client: client, showSubmitButton: true)
        vm.requests = FeatureRequest.previewList
        return vm
    }
}
