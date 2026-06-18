import SwiftUI

struct IdentitySheet: View {
    @State private var displayName = ""
    @State private var email = ""
    var onComplete: (UserIdentity) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Shown next to your comments and requests.")
                }

                Section {
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } footer: {
                    Text("Only visible to the developer.")
                }
            }
            .navigationTitle("Identify Yourself")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        let identity = UserIdentity(
                            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? nil
                                : email.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        IdentityStore.save(identity)
                        onComplete(identity)
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .interactiveDismissDisabled()
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    IdentitySheet { identity in
        print(identity.displayName)
    }
}
