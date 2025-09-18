//
//  MovieDetailViewModel.swift
//  MoviesDetails
//

import Foundation
import MoviesDomain

@MainActor
@Observable
public final class MovieDetailViewModel {
    public private(set) var movie: MovieDetails?
    public private(set) var isLoading = false
    public private(set) var error: Error?

    @ObservationIgnored private let repository: MovieRepositoryProtocol
    @ObservationIgnored private let favoritesStore: FavoritesStoreProtocol
    @ObservationIgnored private let movieId: Int
    @ObservationIgnored private var currentTask: Task<Void, Never>?

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol, movieId: Int) {
        self.repository = repository
        self.favoritesStore = favoritesStore
        self.movieId = movieId
        fetch()
        Task { [weak self] in
            guard let self else { return }
            // Offline-first: try local details snapshot
            if let local = try? await favoritesStore.getFavoriteDetails(movieId: movieId), self.movie == nil {
                self.movie = local
            }
        }
    }

    // MARK: - View State
    public enum DetailViewState {
        case loading
        case error(Error)
        case content(MovieDetails)
    }

    public var state: DetailViewState {
        switch true {
        case error != nil:
            return .error(error!)
        case movie != nil:
            return .content(movie!)
        default:
            return .loading
        }
    }

    public func fetch() {
        isLoading = true
        error = nil
        currentTask?.cancel()
        currentTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let details = try await self.repository.fetchMovieDetails(id: self.movieId)
                if Task.isCancelled { return }
                self.movie = details
                self.isLoading = false
            } catch is CancellationError {
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
            self.currentTask = nil
        }
    }

    public func toggleFavorite() {
        if favoritesStore.isFavorite(movieId: movieId) {
            // Movie is favorited, so remove it
            favoritesStore.removeFromFavorites(movieId: movieId)
        } else if let details = movie {
            // Movie is not favorited, so add it
            favoritesStore.addToFavorites(details: details)
        }
    }

    public func isFavorite() -> Bool {
        return favoritesStore.isFavorite(movieId: movieId)
    }
}
