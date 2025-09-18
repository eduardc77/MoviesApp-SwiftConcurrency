//
//  SearchView.swift
//  MoviesSearch
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation
import MoviesData
import MoviesDomain
import MoviesDesignSystem

public struct SearchView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: SearchViewModel

    public init(repository: MovieRepositoryProtocol, favoriteStore: FavoritesStoreProtocol) {
        _viewModel = State(initialValue: SearchViewModel(repository: repository, favoritesStore: favoriteStore))
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                ContentUnavailableView {
                    Label(String(localized: .SearchL10n.emptyTitle), systemImage: "magnifyingglass")
                } description: {
                    Text(.SearchL10n.emptyDescription)
                }
            case .loading:
                LoadingView()
            case .error(let error):
                ContentUnavailableView {
                    Label(String(localized: .SearchL10n.errorTitle), systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button(String(localized: .DesignSystemL10n.retry)) {
                        if !viewModel.query.isEmpty {
                            viewModel.search(reset: true, trigger: .submit)
                        }
                    }
                    .tint(.primary)
                    .buttonStyle(.bordered)
                }
            case .empty:
                ContentUnavailableView {
                    Label(String(localized: .SearchL10n.noResultsDescription), systemImage: "film")
                } description: {
                    Text(.SearchL10n.noResultsDescription)
                }
            case .content:
                CardGridView(items: viewModel.items,
                             onTap: { item in appRouter.navigateToMovieDetails(movieId: item.id) },
                             onFavoriteToggle: { item in viewModel.toggleFavorite(item.id) },
                             isFavorite: { item in viewModel.isFavorite(item.id) },
                             onLoadNext: { viewModel.search(reset: false, trigger: .submit) },
                             showLoadingOverlay: viewModel.isLoadingNext,
                             onRefresh: { await viewModel.refresh() })
            }
        }
        .navigationTitle(Text(.SearchL10n.title))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String(localized: .SearchL10n.searchPrompt))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.4))
        .onSubmit(of: .search) {
            viewModel.search(reset: true, trigger: .submit)
        }
        #endif
    }
}
