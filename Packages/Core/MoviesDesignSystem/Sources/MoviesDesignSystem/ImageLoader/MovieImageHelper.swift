//
//  MovieImageHelper.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesNetwork

/// Helper for building movie image URLs in the presentation layer
/// Uses the configured NetworkingConfig instead of hardcoded URLs
public struct MovieImageHelper {
    private let config: NetworkingConfig

    public init(config: NetworkingConfig) {
        self.config = config
    }

    /// Build poster URL for a movie
    /// - Parameters:
    ///   - posterPath: The poster path from TMDB API
    ///   - size: Desired image size
    /// - Returns: Complete URL for the poster image
    public func posterURL(posterPath: String?, size: ImageURLBuilder.ImageSize = .medium) -> URL? {
        ImageURLBuilder.posterURL(posterPath: posterPath, config: config, size: size)
    }

    /// Build backdrop URL for a movie
    /// - Parameters:
    ///   - backdropPath: The backdrop path from TMDB API
    ///   - size: Desired image size
    /// - Returns: Complete URL for the backdrop image
    public func backdropURL(backdropPath: String?, size: ImageURLBuilder.ImageSize = .large) -> URL? {
        ImageURLBuilder.backdropURL(backdropPath: backdropPath, config: config, size: size)
    }
}
