//
//  FavoritesViewModel.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import Foundation
import Combine
import Observation
import MoviesDomain

@MainActor
@Observable
public final class FavoritesViewModel {
    public private(set) var items: [Movie] = []
    public private(set) var isLoading: Bool = false
    public private(set) var isLoadingNext: Bool = false
    public private(set) var error: Error?
    public var sortOrder: MovieSortOrder?

    @ObservationIgnored private let repository: MovieRepositoryProtocol
    public let favoritesStore: FavoritesStoreProtocol
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var currentPage = 1
    @ObservationIgnored private var pageSize = 20
    @ObservationIgnored private var canLoadMore = true

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol) {
        self.repository = repository
        self.favoritesStore = favoritesStore
    }

    // MARK: - View State
    public enum FavoritesViewState {
        case loading
        case error(Error)
        case empty
        case content(items: [Movie], isLoadingNext: Bool)
    }

    public var state: FavoritesViewState {
        switch true {
        case error != nil:
            return .error(error!)
        case isLoading && items.isEmpty:
            return .loading
        case items.isEmpty:
            return .empty
        default:
            return .content(items: items, isLoadingNext: isLoadingNext)
        }
    }

    /// async refresh method for pull-to-refresh
    public func refresh() async { load(reset: true) }

    public func reload() { favoritesDidChange() }

    /// Called by the View when it detects changes via onChange
    /// This allows the View to trigger reloads when the store's favorites change
    public func favoritesDidChange() { load(reset: true) }

    private func load(reset: Bool) {
        if reset {
            isLoading = true
            isLoadingNext = false
            error = nil
            items = []
            currentPage = 1
            canLoadMore = true
        } else {
            guard !isLoadingNext, canLoadMore else { return }
            isLoadingNext = true
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let page = currentPage
                let result = try await favoritesStore.getFavorites(page: page, pageSize: pageSize, sortOrder: sortOrder)
                await MainActor.run {
                    if reset { self.items = result } else { self.items.append(contentsOf: result) }
                    self.isLoading = false
                    self.isLoadingNext = false
                    self.canLoadMore = result.count == self.pageSize
                    if self.canLoadMore { self.currentPage += 1 }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    self.isLoadingNext = false
                }
            }
        }
    }

    public func toggleFavorite(_ id: Int) {
        if favoritesStore.isFavorite(movieId: id) {
            // Movie is favorited, so remove it
            favoritesStore.removeFromFavorites(movieId: id)
        } else if let movie = items.first(where: { $0.id == id }) {
            // Movie is not favorited, so add it
            favoritesStore.addToFavorites(movie: movie)
        }
    }
    public func isFavorite(_ id: Int) -> Bool { favoritesStore.isFavorite(movieId: id) }

    public func setSortOrder(_ order: MovieSortOrder) {
        // Mark that sort changed for scroll-to-top UX
        sortOrder = order
        // Reload using local sort
        load(reset: true)
    }

    public func loadNextIfNeeded(currentItem: Movie?) {
        guard let id = currentItem?.id,
              let idx = items.firstIndex(where: { $0.id == id }),
              idx >= max(items.count - 3, 0) else { return }
        load(reset: false)
    }
}
