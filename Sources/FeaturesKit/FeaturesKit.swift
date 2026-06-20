import SwiftUI

public struct FeaturesKit: View {
    @State private var viewModel: FeaturesViewModel
    @State private var showIdentitySheet: Bool

    private let appManagedIdentity: Bool
    private let theme: FeaturesTheme

    public init(
        _ apiKey: String,
        baseURL: String = "https://your-domain.com",
        userId: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        showSubmitButton: Bool = true,
        showLimitDisplay: Bool = false,
        theme: FeaturesTheme = FeaturesTheme()
    ) {
        self.theme = theme
        let identity: UserIdentity?
        let needsSheet: Bool

        if let displayName {
            identity = UserIdentity(displayName: displayName, email: email)
            needsSheet = false
            self.appManagedIdentity = true
        } else if let stored = IdentityStore.load() {
            identity = stored
            needsSheet = false
            self.appManagedIdentity = false
        } else {
            identity = nil
            needsSheet = true
            self.appManagedIdentity = false
        }

        let client = FeaturesClient(
            apiKey: apiKey,
            baseURL: baseURL,
            userId: userId,
            displayName: identity?.displayName,
            email: identity?.email
        )
        _viewModel = State(initialValue: FeaturesViewModel(client: client, showSubmitButton: showSubmitButton, showLimitDisplay: showLimitDisplay))
        _showIdentitySheet = State(initialValue: needsSheet)
    }

    public var body: some View {
        RequestListView(viewModel: viewModel)
            .environment(\.featuresTheme, theme)
            .sheet(isPresented: $showIdentitySheet) {
                IdentitySheet { identity in
                    viewModel.client.updateIdentity(displayName: identity.displayName, email: identity.email)
                    showIdentitySheet = false
                }
            }
    }
}

#Preview {
    @Previewable @State var vm: FeaturesViewModel = .preview
    NavigationStack {
        RequestListView(viewModel: vm)
    }
}
