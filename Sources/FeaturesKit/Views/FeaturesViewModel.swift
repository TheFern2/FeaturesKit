import Foundation
import Observation

@MainActor @Observable
final class FeaturesViewModel {
    var requests: [FeatureRequest] = []
    var filter: RequestFilter = .all
    var sort: SortOrder = .votes
    var isLoading = false
    var error: String?
    var isOffline = false
    var limitInfo: RequestLimitInfo?

    let client: FeaturesClient
    let showSubmitButton: Bool

    init(client: FeaturesClient, showSubmitButton: Bool) {
        self.client = client
        self.showSubmitButton = showSubmitButton
    }

    var isAtLimit: Bool {
        limitInfo?.limitRemaining == 0
    }

    var limitDisplay: String? {
        guard let info = limitInfo else { return nil }
        return "\(info.requestCount) / \(info.requestLimit) requests"
    }

    var filteredRequests: [FeatureRequest] {
        switch filter {
        case .all:
            return requests
        case .planned:
            return requests.filter { $0.status == .planned || $0.status == .inProgress || $0.status == .underReview }
        case .shipped:
            return requests.filter { $0.status == .shipped }
        }
    }

    var emptyMessage: String {
        switch filter {
        case .all: "No requests yet"
        case .planned: "Nothing planned yet"
        case .shipped: "Nothing shipped yet"
        }
    }

    func loadRequests() async {
        isLoading = true
        error = nil
        do {
            await replayPendingActions()
            let response = try await client.listRequests(sort: sort)
            requests = response.requests
            updateLimitInfo(from: response.meta)
            isOffline = false
            RequestCache.save(response.requests)
        } catch {
            if let cached = RequestCache.load() {
                requests = cached
                isOffline = true
            } else {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }

    func updateVote(requestId: String, voted: Bool, count: Int) {
        guard let index = requests.firstIndex(where: { $0.id == requestId }) else { return }
        requests[index] = requests[index].withVote(voted, count: count)
    }

    func vote(requestId: String) async {
        guard let index = requests.firstIndex(where: { $0.id == requestId }) else { return }
        let original = requests[index]
        let wasVoted = original.voted
        let newCount = wasVoted ? original.voteCount - 1 : original.voteCount + 1

        requests[index] = original.withVote(!wasVoted, count: newCount)

        do {
            if wasVoted {
                _ = try await client.unvote(requestId: requestId)
            } else {
                _ = try await client.vote(requestId: requestId)
            }
        } catch {
            if isNetworkError(error) {
                let action: PendingAction = wasVoted ? .unvote(requestId: requestId) : .vote(requestId: requestId)
                PendingActionQueue.enqueue(action)
            } else {
                requests[index] = original
            }
        }
    }

    func submitRequest(title: String, description: String?) async throws {
        do {
            let newRequest = try await client.createRequest(title: title, description: description)
            requests.insert(newRequest, at: 0)
            if var info = limitInfo {
                info = RequestLimitInfo(
                    requestLimit: info.requestLimit,
                    requestCount: info.requestCount + 1,
                    limitRemaining: max(0, info.limitRemaining - 1)
                )
                limitInfo = info
            }
        } catch {
            if case FeaturesError.requestLimitReached(let info) = error {
                limitInfo = info
                throw error
            } else if isNetworkError(error) {
                PendingActionQueue.enqueue(.submit(title: title, description: description))
            } else {
                throw error
            }
        }
    }

    private func replayPendingActions() async {
        let pending = PendingActionQueue.load()
        guard !pending.isEmpty else { return }

        var remaining: [PendingAction] = []
        for action in pending {
            do {
                switch action {
                case .vote(let requestId):
                    _ = try await client.vote(requestId: requestId)
                case .unvote(let requestId):
                    _ = try await client.unvote(requestId: requestId)
                case .submit(let title, let description):
                    _ = try await client.createRequest(title: title, description: description)
                }
            } catch {
                if isNetworkError(error) {
                    remaining.append(action)
                }
            }
        }

        if remaining.isEmpty {
            PendingActionQueue.clear()
        } else {
            PendingActionQueue.save(remaining)
        }
    }

    private func updateLimitInfo(from meta: RequestLimitMeta) {
        guard let limit = meta.requestLimit, let count = meta.requestCount, let remaining = meta.limitRemaining else {
            limitInfo = nil
            return
        }
        limitInfo = RequestLimitInfo(requestLimit: limit, requestCount: count, limitRemaining: remaining)
    }

    private func isNetworkError(_ error: Error) -> Bool {
        if case FeaturesError.networkError = error { return true }
        return false
    }
}

enum RequestFilter: String, CaseIterable {
    case all = "All"
    case planned = "Planned"
    case shipped = "Shipped"
}
