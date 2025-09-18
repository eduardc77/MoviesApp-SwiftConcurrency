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
        didSet { onQueryChanged(query) }
    }

    @ObservationIgnored private var page = 1
    @ObservationIgnored private var totalPages = 1
    @ObservationIgnored private var currentTask: Task<Void, Never>?

    @ObservationIgnored private let repository: MovieRepositoryProtocol
    @ObservationIgnored private let favoritesStore: FavoritesStoreProtocol
    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    public enum Trigger { case debounce, submit }

    var isQueryShort: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3
    }

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol) {
        self.repository = repository
        self.favoritesStore = favoritesStore
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
        await performSearch(reset: true, trigger: .submit)
    }

    public func search(reset: Bool = true, trigger: Trigger) {
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

        // cancel previous task
        currentTask?.cancel()
        let q = trimmed
        currentTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let pageResult = try await self.repository.searchMovies(query: q, page: next)
                if Task.isCancelled { return }
                self.page = pageResult.page
                self.totalPages = pageResult.totalPages
                let existing = Set(self.items.map(\.id))
                let newItems = pageResult.items.filter { !existing.contains($0.id) }
                self.items.append(contentsOf: newItems)
            } catch is CancellationError {
                // ignore
            } catch {
                self.error = error
            }
            self.isLoading = false
            self.isLoadingNext = false
            self.currentTask = nil
        }
    }

    public var canLoadMore: Bool { page < totalPages }

    public func isFavorite(_ id: Int) -> Bool { favoritesStore.favoriteMovieIds.contains(id) }
    public func toggleFavorite(_ id: Int) {
        if favoritesStore.isFavorite(movieId: id) {
            // Movie is favorited, so remove it
            favoritesStore.removeFromFavorites(movieId: id)
        } else if let movie = items.first(where: { $0.id == id }) {
            // Movie is not favorited, so add it
            favoritesStore.addToFavorites(movie: movie)
        }
    }

    public func loadNextIfNeeded(currentItem: Movie?) {
        guard let id = currentItem?.id,
              let idx = items.firstIndex(where: { $0.id == id }),
              idx >= max(items.count - 3, 0) else { return }
        search(reset: false, trigger: .submit)
    }

    /// Resets state and manages loading status
    private func resetState(startLoading: Bool = false) {
        // Cancel any in-flight task to prevent memory leaks
        currentTask?.cancel()
        currentTask = nil

        // Reset all state
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
        resetState(startLoading: false)
    }

    // MARK: - Debounce handling with Task
    public func onQueryChanged(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { cancelAndClear(); return }
        if trimmed.count < 3 { return }
        // show loading immediately
        isLoading = true
        error = nil
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(reset: true, trigger: .debounce)
        }
    }

    private func performSearch(reset: Bool, trigger: Trigger) async {
        await MainActor.run { self.search(reset: reset, trigger: trigger) }
    }
}
