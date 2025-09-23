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

    public init(repository: MovieRepositoryProtocol, favoritesStore: FavoritesStoreProtocol, movieId: Int) {
        self.repository = repository
        self.favoritesStore = favoritesStore
        self.movieId = movieId
        Task {
            await fetch()
        }
        // Offline-first: try local details snapshot
        if let local = favoritesStore.getFavoriteDetails(movieId: movieId), self.movie == nil {
            self.movie = local
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

    public func fetch() async {
        isLoading = true
        error = nil

        do {
            let details = try await repository.fetchMovieDetails(id: movieId)
            self.movie = details
            self.isLoading = false
        } catch is CancellationError {
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    public func toggleFavorite() {
        _ = favoritesStore.toggleFavorite(movieId: movieId, movieDetails: movie)
    }

    public func isFavorite() -> Bool {
        return favoritesStore.isFavorite(movieId: movieId)
    }
}
