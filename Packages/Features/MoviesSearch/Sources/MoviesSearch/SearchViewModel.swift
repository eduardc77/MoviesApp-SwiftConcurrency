//
//  SearchViewModel.swift
//  MoviesSearch
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesDomain

@MainActor
@Observable
public final class SearchViewModel {
    public var items: [Movie] = []
    public var isLoading = false
    public var isLoadingNext = false
    public var error: Error?
    public var query: String = "" {
        didSet { handleQueryChange() }
    }

    @ObservationIgnored private var page = 1
    @ObservationIgnored private var totalPages = 1
    @ObservationIgnored private var currentSearchTask: Task<Void, Never>?

    @ObservationIgnored private let repository: MovieRepositoryProtocol
    @ObservationIgnored private let favoritesStore: FavoritesStoreProtocol

    public enum Trigger {
        case debounce
        case submit
    }

    var isQueryShort: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3
    }

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol) {
        self.repository = repository
        self.favoritesStore = favoritesStore
    }

    private func handleQueryChange() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cancel previous search task
        currentSearchTask?.cancel()

        if trimmed.isEmpty {
            cancelAndClear()
            return
        }

        if trimmed.count >= 3 {
            error = nil
            isLoading = true // Show loading immediately

            // Start new debounced search
            currentSearchTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                if !Task.isCancelled && !isQueryShort {
                    await search(reset: true, trigger: .debounce)
                }
            }
        }
    }

    // MARK: - View State
    public enum SearchViewState {
        case idle // no query yet or too short
        case loading
        case error(Error)
        case empty // valid query but no results
        case content(items: [Movie], isLoadingNext: Bool)
    }

    public var state: SearchViewState {
        switch true {
        case error != nil:
            return .error(error!)
        case isLoading:
            return .loading
        case items.isEmpty && isQueryShort:
            return .idle
        case items.isEmpty:
            return .empty
        default:
            return .content(items: items, isLoadingNext: isLoadingNext)
        }
    }

    /// Async refresh method for pull-to-refresh
    public func refresh() async {
        guard !query.isEmpty else { return }
        await search(reset: true, trigger: .submit)
    }

    public func search(reset: Bool = true, trigger: Trigger) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            items = []
            return
        }
        if trigger == .debounce {
            guard !isQueryShort else { return }
        }
        let next = reset ? 1 : page + 1
        if reset {
            prepareForNewSearch()
        } else {
            guard !isLoadingNext, next <= totalPages else { return }
            isLoadingNext = true
        }

        do {
            let page = try await repository.searchMovies(query: trimmed, page: next)
            self.page = page.page
            self.totalPages = page.totalPages
            // Prevent duplicates across pages for a single query
            let existing = Set(self.items.map(\.id))
            let newItems = page.items.filter { !existing.contains($0.id) }
            self.items.append(contentsOf: newItems)
            self.isLoading = false
            self.isLoadingNext = false
        } catch is CancellationError {
            // Ignore cancellations triggered by new input; just stop loading
            self.isLoading = false
            self.isLoadingNext = false
        } catch {
            self.error = error
            self.isLoading = false
            self.isLoadingNext = false
        }
    }

    public var canLoadMore: Bool { page < totalPages }

    public func isFavorite(_ id: Int) -> Bool { favoritesStore.favoriteMovieIds.contains(id) }
    
    public func toggleFavorite(_ id: Int) {
        _ = favoritesStore.toggleFavorite(movieId: id, in: items)
    }

    public func loadNextIfNeeded(currentItem: Movie?) async {
        guard let id = currentItem?.id,
              let idx = items.firstIndex(where: { $0.id == id }),
              idx >= max(items.count - 3, 0) else { return }
        await search(reset: false, trigger: .submit)
    }

    /// Resets state and manages loading status
    private func resetState(startLoading: Bool = false) {
        // Don't cancel the current task if we're being called from within it
        // Just reset the state without cancelling
        isLoading = startLoading
        isLoadingNext = false
        error = nil
        items.removeAll()
        page = 1
        totalPages = 1
    }

    /// Prepares state for a new search (shows loading)
    private func prepareForNewSearch() {
        resetState(startLoading: true)
    }

    /// Cancels ongoing requests and clears state (stops loading)
    private func cancelAndClear() {
        // Cancel any in-flight search task when clearing
        currentSearchTask?.cancel()
        currentSearchTask = nil
        resetState(startLoading: false)
    }
}
