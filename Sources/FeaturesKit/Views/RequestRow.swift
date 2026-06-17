import SwiftUI

struct RequestRow: View {
    let request: FeatureRequest
    let onVote: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onVote()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(request.voteCount)")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(width: 44, height: 50)
                .foregroundStyle(request.voted ? Color.white : Color.accentColor)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(request.voted ? Color.accentColor : Color.accentColor.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor.opacity(request.voted ? 0 : 0.3))
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(request.title)
                    .font(.headline)
                    .lineLimit(1)

                if let description = request.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    statusBadge

                    if request.commentCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bubble.right")
                            Text("\(request.commentCount)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (label, color) = statusInfo(request.status)
        if request.status != .new {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2), in: Capsule())
        }
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
}

#Preview {
    List {
        RequestRow(request: .preview) {}
        RequestRow(request: FeatureRequest(
            id: "2", title: "Export to PDF",
            description: "Let me export reports as PDF files for sharing.",
            status: .new, visibility: .approved,
            voteCount: 18, commentCount: 1, voted: true, deviceId: "d",
            createdAt: .now, updatedAt: .now
        )) {}
    }
}
