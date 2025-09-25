//
//  FavoritesView.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesDesignSystem
import MoviesDomain
import MoviesNavigation

/// Main view for displaying favorite movies
public struct FavoritesView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: FavoritesViewModel
    @State private var shouldScrollToTop = false

    public init(favoriteStore: FavoritesStoreProtocol) {
        _viewModel = State(initialValue: FavoritesViewModel(favoritesStore: favoriteStore))
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .error(let error):
                ContentUnavailableView {
                    Label(String(localized: .FavoritesL10n.errorTitle), systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button(String(localized: .DesignSystemL10n.retry)) {
                        viewModel.reload()
                    }
                    .tint(.primary)
                    .buttonStyle(.bordered)
                }
            case .empty:
                ContentUnavailableView {
                    Label(String(localized: .FavoritesL10n.emptyTitle), systemImage: "heart.fill")
                } description: {
                    Text(.FavoritesL10n.emptyDescription)
                }
            case .content(let items):
                CardGridView(items: items,
                             onTap: { item in appRouter.navigateToMovieDetails(movieId: item.id) },
                             onFavoriteToggle: { item in viewModel.toggleFavorite(item.id) },
                             isFavorite: { item in viewModel.isFavorite(item.id) },
                             onLoadNext: {
                                 viewModel.loadNextIfNeeded(currentItem: viewModel.items.last)
                             },
                             showLoadingOverlay: viewModel.isLoadingNext,
                             onRefresh: { await viewModel.refresh() },
                             shouldScrollToTop: $shouldScrollToTop)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Text(.FavoritesL10n.title))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sortToolbar(
            onPresentDialog: { sortOrder, onSelect in
                // Exclude popularity-based sorts for favorites to ensure consistent ordering
                let favoriteSortOptions = MovieSortOrder.allCases.filter { $0 != .popularityAscending && $0 != .popularityDescending }
                appRouter.presentSortOptions(available: favoriteSortOptions, current: sortOrder) { selectedOption in
                    onSelect(selectedOption)
                }
            },
            currentSortOption: viewModel.sortOrder
        ) { order in
            viewModel.setSortOrder(order)
            shouldScrollToTop = true
        }
        .task(id: viewModel.favoritesStore.favoriteMovieIds) {
            if viewModel.items.isEmpty {
                await viewModel.refresh()        // initial load
            } else {
                viewModel.favoritesDidChange()   // incremental updates
            }
        }
    }
}
