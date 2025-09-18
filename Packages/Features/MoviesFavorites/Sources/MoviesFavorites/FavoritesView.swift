//
//  FavoritesView.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesDesignSystem
import MoviesDomain
import MoviesData
import MoviesNavigation

/// Main view for displaying favorite movies
public struct FavoritesView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: FavoritesViewModel

    public init(repository: MovieRepositoryProtocol, favoriteStore: FavoritesStoreProtocol) {
        _viewModel = State(initialValue: FavoritesViewModel(repository: repository, favoritesStore: favoriteStore))
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
            case .content:
                CardGridView(items: viewModel.items,
                             onTap: { item in appRouter.navigateToMovieDetails(movieId: item.id) },
                             onFavoriteToggle: { item in viewModel.toggleFavorite(item.id) },
                             isFavorite: { item in viewModel.isFavorite(item.id) },
                             onLoadNext: { viewModel.loadNextIfNeeded(currentItem: viewModel.items.last) },
                             showLoadingOverlay: viewModel.isLoadingNext,
                             onRefresh: { await viewModel.refresh() })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.4))
        .navigationTitle(Text(.FavoritesL10n.title))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sortToolbar(
            onPresentDialog: { sortOrder, onSelect in
                appRouter.presentSortOptions(current: sortOrder) { selectedOption in
                    onSelect(selectedOption)
                }
            },
            currentSortOption: viewModel.sortOrder
        ) { order in
            viewModel.setSortOrder(order)
        }
        .task(id: viewModel.favoritesStore.favoriteMovieIds) {
            viewModel.favoritesDidChange()
        }
    }
}
