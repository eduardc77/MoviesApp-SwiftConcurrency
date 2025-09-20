//
//  HomeView.swift
//  MoviesHome
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation
import MoviesDomain
import MoviesDesignSystem

public struct HomeView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: HomeViewModel

    @State private var selectedTab: HomeCategory = .nowPlaying

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    public init(repository: MovieRepositoryProtocol, favoriteStore: FavoritesStoreProtocol) {
        _viewModel = State(initialValue: HomeViewModel(repository: repository, favoritesStore: favoriteStore))
    }

    public var body: some View {
        VStack(spacing: 0) {
            TopFilterBar<HomeCategory>(
                currentFilter: $selectedTab,
                activeColor: .white,
                inactiveColor: .white.opacity(0.6),
                underlineColor: .white
            )
            .background(Color.black)

            switch viewModel.state {
            case .loading:
                LoadingView()
            case .error(let error):
                ContentUnavailableView {
                    Label(String(localized: .HomeL10n.errorTitle), systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button(String(localized: .DesignSystemL10n.retry)) {
                        Task {
                            await viewModel.load(reset: true)
                        }
                    }
                    .tint(.primary)
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                ContentUnavailableView {
                    Label(String(localized: .HomeL10n.title), systemImage: "film")
                } description: {
                    Text(String(localized: .DesignSystemL10n.none))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content(_, _):
                TabView(selection: $selectedTab) {
                    ForEach(HomeCategory.allCases) { category in
                        CardGridView(
                            items: viewModel.items,
                            onTap: { appRouter.navigateToMovieDetails(movieId: $0.id) },
                            onFavoriteToggle: { viewModel.toggleFavorite($0.id) },
                            isFavorite: { viewModel.isFavorite($0.id) },
                            onLoadNext: {
                                Task {
                                    await viewModel.loadNextIfNeeded(currentItem: viewModel.items.last)
                                }
                            },
                            showLoadingOverlay: viewModel.isLoadingNext,
                            onRefresh: { await viewModel.refresh() }
                        )
                        .tag(category)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }

        }
        .navigationTitle(Text(.HomeL10n.title))
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
            Task {
                await viewModel.setSortOrder(order)
            }
        }
        .task {
            if viewModel.items.isEmpty {
                viewModel.category = .nowPlaying
                await viewModel.load(reset: true)
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            Task {
                switch newTab {
                case .nowPlaying: await viewModel.setCategory(.nowPlaying)
                case .popular: await viewModel.setCategory(.popular)
                case .topRated: await viewModel.setCategory(.topRated)
                case .upcoming: await viewModel.setCategory(.upcoming)
                }
            }
        }
    }
}
