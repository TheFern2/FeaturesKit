import SwiftUI

struct RequestDetailView: View {
    @Environment(\.featuresTheme) private var theme
    let requestId: String
    let client: FeaturesClient
    var onVoteChanged: ((Bool, Int) -> Void)?

    @State private var detail: FeatureRequestDetail?
    @State private var voted = false
    @State private var voteCount = 0
    @State private var isLoading = false
    @State private var showSpinner = false
    @State private var error: String?
    @State private var commentText = ""
    @State private var isSendingComment = false
    @State private var showCommentSheet = false

    var body: some View {
        List {
            if let detail {
                detailSection(detail)
                    .listRowBackground(theme.rowBackgroundColor)
                    .listRowSeparator(.hidden)
                commentsSection(detail.comments)
                    .listRowBackground(theme.rowBackgroundColor)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .scrollContentBackground(theme.backgroundColor != nil ? .hidden : .automatic)
        .background((theme.backgroundColor ?? Color.clear).ignoresSafeArea())
        .overlay {
            if showSpinner && detail == nil {
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
            }
        }
        .navigationTitle("Request")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if detail?.commentsLocked != true && detail?.visibility == .approved {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCommentSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            addCommentSheet
                .environment(\.featuresTheme, theme)
        }
        .task { await load() }
    }

    private func detailSection(_ detail: FeatureRequestDetail) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(detail.title)
                    .font(.title3.weight(.semibold))

                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                    Text(submitterLabel(detail))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

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
                        .foregroundStyle(voted ? theme.accent : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(detail.status.isTerminal)

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
            if comments.isEmpty && detail?.commentsLocked != true {
                Text("No comments yet")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
            if detail?.commentsLocked == true {
                Label("Comments are locked", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)
            }
        } header: {
            Text("Comments (\(detail?.comments.count ?? 0))")
        }
        .id("comments-bottom")
    }

    private var addCommentSheet: some View {
        NavigationStack {
            Form {
                Section("Comment") {
                    TextField("Write a comment...", text: $commentText, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollContentBackground(theme.backgroundColor != nil ? .hidden : .automatic)
            .background((theme.backgroundColor ?? Color.clear).ignoresSafeArea())
            .navigationTitle("Add Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        commentText = ""
                        showCommentSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSendingComment {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Post") {
                            Task { await sendComment() }
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func submitterLabel(_ detail: FeatureRequestDetail) -> String {
        if let name = detail.displayName, !name.isEmpty {
            return name
        }
        let id = detail.deviceId
        if id.count > 8 {
            return String(id.prefix(8)) + "..."
        }
        return id
    }

    private func statusBadge(_ status: RequestStatus) -> some View {
        let color = theme.statusColor(status)
        return Text(status.label)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
    }

    private func load() async {
        error = nil
        let spinnerTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled { showSpinner = true }
        }
        do {
            let result = try await client.getRequest(id: requestId)
            spinnerTask.cancel()
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showSpinner = false
                detail = result
                voted = result.voted
                voteCount = result.voteCount
            }
        } catch {
            spinnerTask.cancel()
            showSpinner = false
            self.error = error.localizedDescription
        }
    }

    private func toggleVote() {
        let wasVoted = voted
        voted.toggle()
        voteCount += voted ? 1 : -1
        onVoteChanged?(voted, voteCount)

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
                onVoteChanged?(voted, voteCount)
            }
        }
    }

    private func sendComment() async {
        let body = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            print("[FeaturesKit] sendComment: body is empty, skipping")
            return
        }

        print("[FeaturesKit] sendComment: sending comment for request \(requestId), body length: \(body.count)")
        isSendingComment = true
        do {
            let comment = try await client.addComment(requestId: requestId, body: body)
            print("[FeaturesKit] sendComment: success, comment id: \(comment.id)")
            isSendingComment = false
            commentText = ""
            showCommentSheet = false
            await load()
        } catch {
            print("[FeaturesKit] sendComment: failed with error: \(error)")
            isSendingComment = false
        }
    }
}
