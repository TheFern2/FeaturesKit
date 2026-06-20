import SwiftUI

struct CommentRow: View {
    @Environment(\.featuresTheme) private var theme
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(authorLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(comment.isDeveloper ? theme.accent : Color.secondary)
                Spacer()
                Text(comment.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(comment.body)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, comment.isDeveloper ? 8 : 0)
        .background(
            comment.isDeveloper
                ? theme.accent.opacity(0.15)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private var authorLabel: String {
        if comment.isDeveloper {
            return "Developer"
        }
        if let name = comment.displayName, !name.isEmpty {
            return name
        }
        let id = comment.deviceId
        if id.count > 8 {
            return String(id.prefix(8)) + "..."
        }
        return id
    }
}

#Preview {
    List {
        ForEach(Comment.previewList) { comment in
            CommentRow(comment: comment)
        }
    }
}
