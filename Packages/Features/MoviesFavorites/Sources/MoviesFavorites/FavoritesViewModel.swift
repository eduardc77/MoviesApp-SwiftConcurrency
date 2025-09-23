//
//  FavoritesViewModel.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import Observation
import SwiftUI
import MoviesDomain

@MainActor
@Observable
public final class FavoritesViewModel {
    public private(set) var items: [Movie] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: Error?
    public var sortOrder: MovieSortOrder? = .recentlyAdded
    private var isInitialLoading: Bool = true
    private var pageCursor: FavoritesPageCursor?
    private let pageSize: Int = FavoritesPagingDefaults.pageSize
    public private(set) var isLoadingNext: Bool = false
    private var previousFavoriteIds: Set<Int>? = nil

    public let favoritesStore: FavoritesStoreProtocol

    public init(favoritesStore: FavoritesStoreProtocol) {
        self.favoritesStore = favoritesStore
    }

    // MARK: - View State
    public enum FavoritesViewState {
        case loading
        case error(Error)
        case empty
        case content(items: [Movie])
    }

    public var state: FavoritesViewState {
        switch true {
        case isInitialLoading:
            return .loading
        case isLoading && items.isEmpty:
            return .loading
        case (error != nil) && items.isEmpty:
            return .error(error!)
        case items.isEmpty:
            return .empty
        default:
            return .content(items: items)
        }
    }

    /// async refresh method for pull-to-refresh
    public func refresh() async { load(reset: true) }

    public func reload() { loadAll() }

    /// Called by the View when it detects changes via onChange
    /// Apply incremental updates for best animations and performance
    public func favoritesDidChange() {
        // Avoid racing with initial/full loads
        if isInitialLoading || isLoading { return }

        let currentFavoriteIds = favoritesStore.favoriteMovieIds
        guard let prev = previousFavoriteIds else {
            // Establish baseline after first load
            previousFavoriteIds = currentFavoriteIds
            return
        }
        let addedIds = currentFavoriteIds.subtracting(prev)
        let removedIds = prev.subtracting(currentFavoriteIds)
        if addedIds.isEmpty && removedIds.isEmpty { return }

        // Remove unfavorited items
        if !removedIds.isEmpty {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                items.removeAll { removedIds.contains($0.id) }
            }
        }

        // Add new favorites (batch insert for all sorts, including recently added)
        if !addedIds.isEmpty {
            Task { [weak self, sortOrder] in
                guard let self else { return }
                var additions: [Movie] = []
                for id in addedIds {
                    if let details = self.favoritesStore.getFavoriteDetails(movieId: id) {
                        additions.append(details.asMovie)
                    }
                }
                await MainActor.run {
                    self.batchInsert(movies: additions, order: sortOrder)
                }
            }
        }

        // Update baseline after applying changes
        previousFavoriteIds = currentFavoriteIds
    }

    private func load(reset: Bool) {
        if reset {
            isLoading = true
            error = nil
            if isInitialLoading { items = [] }
        }
        Task { [sortOrder] in
            if Task.isCancelled { return }
            let effectiveOrder = sortOrder ?? .recentlyAdded
            let page = await favoritesStore.fetchFirstPage(sortOrder: effectiveOrder, pageSize: pageSize)
            if Task.isCancelled {
                await MainActor.run { self.isLoading = false }
                return
            }
            await MainActor.run {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    self.items = page.items
                }
                self.pageCursor = page.cursor
                self.isLoading = false
                self.isInitialLoading = false
                self.previousFavoriteIds = self.favoritesStore.favoriteMovieIds
            }
        }
    }

    /// Reload without toggling loading state to keep grid on-screen and animate diffs
    private func insertMovie(_ movie: Movie, order: MovieSortOrder?) {
        guard let order else {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) { items.insert(movie, at: 0) }
            return
        }
        if order == .recentlyAdded {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) { items.insert(movie, at: 0) }
            return
        }
        // Find insertion index based on sort
        let idx = items.firstIndex { existing in shouldInsertBefore(movie, existing, sortOrder: order) } ?? items.count
        withAnimation(.spring(duration: 0.3, bounce: 0.2)) { items.insert(movie, at: idx) }
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
        case .recentlyAdded:
            return false
        }
    }

    private func sortMovies(_ movies: [Movie], for order: MovieSortOrder) -> [Movie] {
        switch order {
        case .popularityAscending:
            return movies.sorted { lhs, rhs in
                if lhs.popularity == rhs.popularity { return lhs.id < rhs.id }
                return lhs.popularity < rhs.popularity
            }
        case .popularityDescending:
            return movies.sorted { lhs, rhs in
                if lhs.popularity == rhs.popularity { return lhs.id < rhs.id }
                return lhs.popularity > rhs.popularity
            }
        case .ratingAscending:
            return movies.sorted { lhs, rhs in
                if lhs.voteAverage == rhs.voteAverage { return lhs.id < rhs.id }
                return lhs.voteAverage < rhs.voteAverage
            }
        case .ratingDescending:
            return movies.sorted { lhs, rhs in
                if lhs.voteAverage == rhs.voteAverage { return lhs.id < rhs.id }
                return lhs.voteAverage > rhs.voteAverage
            }
        case .releaseDateAscending:
            return movies.sorted { lhs, rhs in
                if lhs.releaseDate == rhs.releaseDate { return lhs.id < rhs.id }
                return lhs.releaseDate < rhs.releaseDate
            }
        case .releaseDateDescending:
            return movies.sorted { lhs, rhs in
                if lhs.releaseDate == rhs.releaseDate { return lhs.id < rhs.id }
                return lhs.releaseDate > rhs.releaseDate
            }
        case .recentlyAdded:
            // We do not have createdAt on Movie; recent adds are inserted at front
            return movies.sorted { $0.id < $1.id }
        }
    }

    private func batchInsert(movies: [Movie], order: MovieSortOrder?) {
        guard !movies.isEmpty else { return }
        var newItems = self.items
        let uniqueAdds = movies.filter { movie in !newItems.contains(where: { $0.id == movie.id }) }
        guard !uniqueAdds.isEmpty else { return }

        if let order {
            if order == .recentlyAdded {
                newItems.insert(contentsOf: uniqueAdds, at: 0)
            } else {
                let sortedAdds = sortMovies(uniqueAdds, for: order)
                for movie in sortedAdds {
                    let idx = newItems.firstIndex { existing in shouldInsertBefore(movie, existing, sortOrder: order) } ?? newItems.count
                    newItems.insert(movie, at: idx)
                }
            }
        } else {
            newItems.insert(contentsOf: uniqueAdds, at: 0)
        }

        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
            self.items = newItems
        }
    }

    private func loadAll() {
        load(reset: true)
    }

    public func toggleFavorite(_ id: Int) {
        _ = favoritesStore.toggleFavorite(movieId: id, in: items)
    }

    public func isFavorite(_ id: Int) -> Bool { favoritesStore.isFavorite(movieId: id) }

    public func setSortOrder(_ order: MovieSortOrder) {
        // Mark that sort changed for scroll-to-top UX
        sortOrder = order
        // Reload first page with new sort
        load(reset: true)
    }

    public func loadNextIfNeeded(currentItem: Movie?) {
        guard let currentItem,
              let tailId = items.last?.id,
              currentItem.id == tailId,
              let cursor = pageCursor,
              !isLoadingNext else { return }
        Task { [weak self, cursor] in
            guard let self else { return }
            self.isLoadingNext = true
            let next = await self.favoritesStore.fetchNextPage(cursor: cursor, pageSize: self.pageSize)
            if Task.isCancelled {
                await MainActor.run { self.isLoadingNext = false }
                return
            }
            await MainActor.run {
                if !next.items.isEmpty {
                    let existing = Set(self.items.map { $0.id })
                    let newOnes = next.items.filter { !existing.contains($0.id) }
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        self.items.append(contentsOf: newOnes)
                    }
                }
                // Advance or clear the cursor even if no new items (end reached or empty page)
                self.pageCursor = next.cursor
                self.isLoadingNext = false
            }
        }
    }
}
