import SwiftUI

public struct FeaturesKit: View {
    @State private var viewModel: FeaturesViewModel

    public init(
        _ apiKey: String,
        baseURL: String = "https://your-domain.com",
        userId: String? = nil,
        showSubmitButton: Bool = true
    ) {
        let client = FeaturesClient(apiKey: apiKey, baseURL: baseURL, userId: userId)
        _viewModel = State(initialValue: FeaturesViewModel(client: client, showSubmitButton: showSubmitButton))
    }

    public var body: some View {
        NavigationStack {
            RequestListView(viewModel: viewModel)
        }
    }
}

#Preview {
    @Previewable @State var vm: FeaturesViewModel = .preview
    NavigationStack {
        RequestListView(viewModel: vm)
    }
}
