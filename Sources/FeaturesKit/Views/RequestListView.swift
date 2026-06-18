import SwiftUI

struct RequestListView: View {
    @Bindable var viewModel: FeaturesViewModel
    @State private var showSubmitSheet = false

    var body: some View {
        List {
            filterPicker
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

            if viewModel.showLimitDisplay, let limitDisplay = viewModel.limitDisplay {
                Text(limitDisplay)
                    .font(.caption)
                    .foregroundStyle(viewModel.isAtLimit ? .orange : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if viewModel.isOffline {
                offlineBanner
            }

            if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Something went wrong", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.loadRequests() }
                    }
                }
            } else if viewModel.filteredRequests.isEmpty && !viewModel.isLoading {
                ContentUnavailableView {
                    Label(viewModel.emptyMessage, systemImage: "lightbulb")
                }
            } else {
                ForEach(viewModel.filteredRequests) { request in
                    NavigationLink {
                        RequestDetailView(requestId: request.id, client: viewModel.client) { voted, count in
                            viewModel.updateVote(requestId: request.id, voted: voted, count: count)
                        }
                    } label: {
                        RequestRow(request: request) {
                            Task { await viewModel.vote(requestId: request.id) }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Feature Requests")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    sortMenu
                    if viewModel.showSubmitButton && !viewModel.isAtLimit {
                        Button {
                            showSubmitSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .listSectionSeparator(.hidden, edges: .top)

        .refreshable {
            await viewModel.loadRequests()
        }
        .task {
            if viewModel.requests.isEmpty {
                await viewModel.loadRequests()
            }
        }
        .sheet(isPresented: $showSubmitSheet) {
            SubmitRequestView(isAtLimit: viewModel.isAtLimit) { title, description in
                try await viewModel.submitRequest(title: title, description: description)
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.filter) {
            ForEach(RequestFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var sortMenu: some View {
        Menu {
            Button {
                viewModel.sort = .votes
                Task { await viewModel.loadRequests() }
            } label: {
                HStack {
                    Text("Most Voted")
                    if viewModel.sort == .votes { Image(systemName: "checkmark") }
                }
            }
            Button {
                viewModel.sort = .newest
                Task { await viewModel.loadRequests() }
            } label: {
                HStack {
                    Text("Newest")
                    if viewModel.sort == .newest { Image(systemName: "checkmark") }
                }
            }
            Button {
                viewModel.sort = .oldest
                Task { await viewModel.loadRequests() }
            } label: {
                HStack {
                    Text("Oldest")
                    if viewModel.sort == .oldest { Image(systemName: "checkmark") }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Showing cached data")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
