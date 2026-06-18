import SwiftUI

struct SubmitRequestView: View {
    let isAtLimit: Bool
    let onSubmit: (String, String?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var error: String?

    private let titleLimit = 200
    private let descriptionLimit = 2000

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Title", text: $title, axis: .vertical)
                            .lineLimit(1...3)
                        Text("\(title.count)/\(titleLimit)")
                            .font(.caption2)
                            .foregroundStyle(title.count > titleLimit ? Color.red : Color.gray)
                    }
                }

                Section {
                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .lineLimit(3...8)
                        Text("\(description.count)/\(descriptionLimit)")
                            .font(.caption2)
                            .foregroundStyle(description.count > descriptionLimit ? Color.red : Color.gray)
                    }
                }

                if isAtLimit {
                    Section {
                        Label("This board has reached its request limit.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Request")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Submit") {
                            Task { await submit() }
                        }
                        .disabled(!canSubmit)
                    }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    private var canSubmit: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isAtLimit
            && !trimmed.isEmpty
            && trimmed.count <= titleLimit
            && description.count <= descriptionLimit
    }

    private func submit() async {
        isSubmitting = true
        error = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await onSubmit(trimmedTitle, trimmedDesc.isEmpty ? nil : trimmedDesc)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}

#Preview {
    SubmitRequestView(isAtLimit: false) { _, _ in }
}
