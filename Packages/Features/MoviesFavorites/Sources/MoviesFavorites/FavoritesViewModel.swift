//
//  FavoritesViewModel.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import Foundation
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
    @ObservationIgnored private var currentPage = 1
    @ObservationIgnored private var pageSize = 20
    @ObservationIgnored private var canLoadMore = true
    @ObservationIgnored private var previousFavoriteIds: Set<Int> = []

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
    public func favoritesDidChange() {
        let currentFavoriteIds = favoritesStore.favoriteMovieIds

        // If this is the first time or we have no items, do a full load
        if items.isEmpty || previousFavoriteIds.isEmpty {
            previousFavoriteIds = currentFavoriteIds
            load(reset: true)
            return
        }

        // Detect changes
        let addedIds = currentFavoriteIds.subtracting(previousFavoriteIds)
        let removedIds = previousFavoriteIds.subtracting(currentFavoriteIds)

        // Update previous state
        previousFavoriteIds = currentFavoriteIds

        // Handle changes synchronously
        if !addedIds.isEmpty {
            handleAddedFavoritesSync(Array(addedIds))
        }
        if !removedIds.isEmpty {
            handleRemovedFavoritesSync(Array(removedIds))
        }

        // If no changes, do nothing
        if addedIds.isEmpty && removedIds.isEmpty {
            return
        }
    }

    private func handleAddedFavoritesSync(_ addedIds: [Int]) {
        // Fetch movie data synchronously and insert
        for movieId in addedIds {
            if let movie = fetchMovieSync(movieId: movieId) {
                insertMovieInSortedOrder(movie)
            }
        }
    }

    private func handleRemovedFavoritesSync(_ removedIds: [Int]) {
        // Remove movies from the array
        items.removeAll { removedIds.contains($0.id) }
    }

    private func fetchMovieSync(movieId: Int) -> Movie? {
        // Get a single movie from the paginated results (page 1, size 1)
        let movies = favoritesStore.getFavorites(page: 1, pageSize: 1, sortOrder: nil)
        return movies.first { $0.id == movieId }
    }

    private func insertMovieInSortedOrder(_ movie: Movie) {
        guard let sortOrder else {
            // No sort order, insert at the beginning
            items.insert(movie, at: 0)
            return
        }

        // Find the correct insertion point
        for (index, existingMovie) in items.enumerated() {
            if shouldInsertBefore(movie, existingMovie, sortOrder: sortOrder) {
                items.insert(movie, at: index)
                return
            }
        }

        // If no suitable position found, append at the end
        items.append(movie)
    }

    private func shouldInsertBefore(_ newMovie: Movie, _ existingMovie: Movie, sortOrder: MovieSortOrder) -> Bool {
        switch sortOrder {
        case .popularityAscending:
            return newMovie.popularity < existingMovie.popularity
        case .popularityDescending:
            return newMovie.popularity > existingMovie.popularity
        case .ratingAscending:
            return newMovie.voteAverage < existingMovie.voteAverage
        case .ratingDescending:
            return newMovie.voteAverage > existingMovie.voteAverage
        case .releaseDateAscending:
            return newMovie.releaseDate < existingMovie.releaseDate
        case .releaseDateDescending:
            return newMovie.releaseDate > existingMovie.releaseDate
        }
    }

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

        let page = currentPage
        let result = favoritesStore.getFavorites(page: page, pageSize: pageSize, sortOrder: sortOrder)

        if reset {
            self.items = result
            self.previousFavoriteIds = self.favoritesStore.favoriteMovieIds
        } else {
            self.items.append(contentsOf: result)
        }
        self.isLoading = false
        self.isLoadingNext = false
        self.canLoadMore = result.count == self.pageSize
        if self.canLoadMore { self.currentPage += 1 }
    }

    public func toggleFavorite(_ id: Int) {
        _ = favoritesStore.toggleFavorite(movieId: id, in: items)
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
