//
//  HomeViewModel.swift
//  MoviesHome
//
//  Created by User on 9/10/25.
//

import Foundation
import SharedModels
import MoviesDomain
import AppLog

@MainActor
@Observable
public final class HomeViewModel {
    public var items: [Movie] = []
    public var isLoading = false
    public var isLoadingNext = false
    public var error: Error?
    public var sortOrder: MovieSortOrder?
    public var category: MovieType = .nowPlaying

    @ObservationIgnored private var page = 1
    @ObservationIgnored private var totalPages = 1

    @ObservationIgnored private let repository: MovieRepositoryProtocol
    @ObservationIgnored private let favoritesStore: FavoritesStoreProtocol

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol) {
        self.repository = repository
        self.favoritesStore = favoritesStore
    }

    // MARK: - View State
    public enum HomeViewState {
        case loading
        case error(Error)
        case empty
        case content(items: [Movie], isLoadingNext: Bool)
    }

    public var state: HomeViewState {
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

    /// Async refresh method for pull-to-refresh
    public func refresh() async {
        AppLog.home.info("HOME PULL-TO-REFRESH: \(category)")
        // Reset and reload data
        await load(reset: true)
    }

    public func load(reset: Bool = true) async {
        let next = reset ? 1 : page + 1
        AppLog.home.info("HOME REQUEST reset:\(reset) next:\(next) cat:\(category) sort:\(String(describing: self.sortOrder))")

        if reset {
            // If a reset load is already in progress, avoid starting another
            if isLoading { return }
            resetState(startLoading: true)
        } else {
            guard !isLoadingNext, next <= totalPages else { return }
            isLoadingNext = true
        }

        // Use user-selected sort order or default for category
        let effectiveSortOrder = sortOrder ?? getDefaultSortOrder(for: category)

        do {
            let page = try await repository.fetchMovies(
                type: category,
                page: next,
                sortBy: effectiveSortOrder
            )

            AppLog.home.info("HOME RESPONSE page:\(page.page) items:\(page.items.count)")

            // Process pagination
            self.page = page.page
            self.totalPages = page.totalPages

            if reset {
                self.items = page.items
            } else {
                // Handle duplicates and append new items
                let existing = Set(self.items.map(\.id))
                let newItems = page.items.filter { !existing.contains($0.id) }
                self.items.append(contentsOf: newItems)
            }

            self.isLoading = false
            self.isLoadingNext = false
        } catch is CancellationError {
            // Ignore cancellations from rapid user changes
            self.isLoading = false
            self.isLoadingNext = false
        } catch {
            self.error = error
            self.isLoading = false
            self.isLoadingNext = false
            AppLog.home.error("Failed to load movies: \(error.localizedDescription)")
        }
    }

    public func isFavorite(_ id: Int) -> Bool { favoritesStore.favoriteMovieIds.contains(id) }

    public func toggleFavorite(_ id: Int) {
        _ = favoritesStore.toggleFavorite(movieId: id, in: items)
    }

    public func setSortOrder(_ order: MovieSortOrder) async {
        // Store the previous sort order to detect changes
        sortOrder = order

        // Always reload when sorting changes
        await load(reset: true)
    }

    public func clearSortOrder() async {
        if sortOrder != nil {
            sortOrder = nil
            await load(reset: true)
        }
    }

    /// Resets state and manages loading status
    private func resetState(startLoading: Bool = false) {
        // Reset all state
        isLoading = startLoading
        isLoadingNext = false
        error = nil
        items.removeAll()
        page = 1
        totalPages = 1
    }

    public func loadNextIfNeeded(currentItem: Movie?) async {
        guard let id = currentItem?.id,
              let idx = items.firstIndex(where: { $0.id == id }),
              idx >= max(items.count - 3, 0) else { return }
        await load(reset: false)
    }

    // MARK: - Helpers
    private func getDefaultSortOrder(for category: MovieType) -> MovieSortOrder {
        switch category {
        case .popular:
            return .popularityDescending
        case .topRated:
            return .ratingDescending
        case .nowPlaying, .upcoming:
            return .popularityDescending  // Default to popularity for time-based categories
        }
    }

    // MARK: - Category switching
    public func setCategory(_ newCategory: MovieType) async {
        guard newCategory != category else { return }
        category = newCategory
        await load(reset: true)
    }
}
