import SwiftUI

struct RequestDetailView: View {
    let requestId: String
    let client: FeaturesClient

    @State private var detail: FeatureRequestDetail?
    @State private var voted = false
    @State private var voteCount = 0
    @State private var isLoading = true
    @State private var error: String?
    @State private var commentText = ""
    @State private var isSendingComment = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error {
                ContentUnavailableView {
                    Label("Failed to load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") {
                        Task { await load() }
                    }
                }
            } else if let detail {
                content(detail)
            }
        }
        .navigationTitle("Request")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    private func content(_ detail: FeatureRequestDetail) -> some View {
        ScrollViewReader { proxy in
            List {
                detailSection(detail)
                commentsSection(detail.comments)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom) {
                commentInput(proxy: proxy)
            }
        }
    }

    private func detailSection(_ detail: FeatureRequestDetail) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(detail.title)
                    .font(.title3.weight(.semibold))

                if let description = detail.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button {
                        toggleVote()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: voted ? "arrow.up.circle.fill" : "arrow.up.circle")
                                .font(.title3)
                            Text("\(voteCount) votes")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(voted ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    statusBadge(detail.status)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func commentsSection(_ comments: [Comment]) -> some View {
        Section {
            if comments.isEmpty {
                Text("No comments yet")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
        } header: {
            Text("Comments (\(detail?.comments.count ?? 0))")
        }
        .id("comments-bottom")
    }

    private func commentInput(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            TextField("Add a comment...", text: $commentText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                Task { await sendComment(proxy: proxy) }
            } label: {
                if isSendingComment {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingComment)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func statusBadge(_ status: RequestStatus) -> some View {
        let (label, color) = statusInfo(status)
        return Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
    }

    private func statusInfo(_ status: RequestStatus) -> (String, Color) {
        switch status {
        case .new: ("New", .secondary)
        case .underReview: ("Under Review", .orange)
        case .planned: ("Planned", .blue)
        case .inProgress: ("In Progress", .purple)
        case .shipped: ("Shipped", .green)
        case .declined: ("Declined", .red)
        }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            let result = try await client.getRequest(id: requestId)
            detail = result
            voted = result.voted
            voteCount = result.voteCount
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func toggleVote() {
        let wasVoted = voted
        voted.toggle()
        voteCount += voted ? 1 : -1

        Task {
            do {
                if voted {
                    _ = try await client.vote(requestId: requestId)
                } else {
                    _ = try await client.unvote(requestId: requestId)
                }
            } catch {
                voted = wasVoted
                voteCount += wasVoted ? 1 : -1
            }
        }
    }

    private func sendComment(proxy: ScrollViewProxy) async {
        let body = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        isSendingComment = true
        do {
            _ = try await client.addComment(requestId: requestId, body: body)
            commentText = ""
            await load()
            withAnimation {
                proxy.scrollTo("comments-bottom", anchor: .bottom)
            }
        } catch {
            // Comment failed silently for now; the text stays so user can retry
        }
        isSendingComment = false
    }
}
