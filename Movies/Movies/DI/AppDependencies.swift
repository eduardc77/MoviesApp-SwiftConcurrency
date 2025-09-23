//
//  AppDependencies.swift
//  Movies
//
//  Created by User on 9/10/25.
//

import Observation
import SwiftData
import MoviesData
import MoviesDomain
import MoviesNetwork

/// Main dependency injection container for the Movies app
/// Handles configuration loading and dependency wiring
@MainActor
@Observable
public final class AppDependencies {

    // MARK: - Public Dependencies

    /// Repository for movie operations
    public let movieRepository: MovieRepositoryProtocol

    /// Store for managing favorite movies (reactive layer with persistence)
    public let favorites: any FavoritesStoreProtocol

    /// Networking configuration (exposed for debugging)
    public let networkingConfig: NetworkingConfig

    /// Shared SwiftData container used across the app
    public let modelContainer: ModelContainer

    // MARK: - Initialization

    /// Initializes the app environment
    public init() {
        self.networkingConfig = TMDBNetworkingConfig.config
        self.movieRepository = MovieRepository.development()

        // Initialize SwiftData container for favorites schema
        let container: ModelContainer = {
            do { return try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self) }
            catch { fatalError("Failed to initialize ModelContainer: \(error)") }
        }()
        self.modelContainer = container

        // Initialize store (reactive layer) with injected container
        self.favorites = FavoritesStore(
            favoritesLocalDataSource: FavoritesLocalDataSource(container: container),
            container: container
        )
    }

    /// Convenience initializer for testing with custom dependencies
    /// - Parameters:
    ///   - movieRepository: Custom movie repository (for testing)
    ///   - networkingConfig: Custom networking config (for testing)
    public init(
        movieRepository: MovieRepositoryProtocol,
        networkingConfig: NetworkingConfig
    ) {
        self.movieRepository = movieRepository
        let container: ModelContainer = {
            do { return try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self) }
            catch { fatalError("Failed to initialize ModelContainer: \(error)") }
        }()
        self.modelContainer = container
        self.favorites = FavoritesStore(
            favoritesLocalDataSource: FavoritesLocalDataSource(container: container),
            container: container
        )
        self.networkingConfig = networkingConfig
    }
}
