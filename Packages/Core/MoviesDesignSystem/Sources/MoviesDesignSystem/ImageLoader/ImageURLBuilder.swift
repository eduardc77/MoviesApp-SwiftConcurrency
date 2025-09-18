//
//  ImageURLBuilder.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import Foundation
import MoviesNetwork

/// Build TMDB image URLs using configured base URLs
public enum ImageURLBuilder {
    /// Available image sizes for TMDB
    public enum ImageSize: String {
        case small = "w185"
        case medium = "w500"
        case large = "w780"
        case original = "original"
    }

    /// Build poster URL for a movie using configured base URL
    /// - Parameters:
    ///   - posterPath: The poster path from TMDB API
    ///   - config: Networking configuration containing base URLs
    ///   - size: Desired image size (default: medium)
    /// - Returns: Complete URL for the poster image
    public static func posterURL(posterPath: String?, config: NetworkingConfig, size: ImageSize = .medium) -> URL? {
        guard let posterPath = posterPath, !posterPath.isEmpty else { return nil }
        let urlString = "\(config.imageBaseURL)/\(size.rawValue)\(posterPath)"
        return URL(string: urlString)
    }

    /// Build backdrop URL for a movie using configured base URL
    /// - Parameters:
    ///   - backdropPath: The backdrop path from TMDB API
    ///   - config: Networking configuration containing base URLs
    ///   - size: Desired image size (default: large)
    /// - Returns: Complete URL for the backdrop image
    public static func backdropURL(backdropPath: String?, config: NetworkingConfig, size: ImageSize = .large) -> URL? {
        guard let backdropPath = backdropPath, !backdropPath.isEmpty else { return nil }
        let urlString = "\(config.imageBaseURL)/\(size.rawValue)\(backdropPath)"
        return URL(string: urlString)
    }
}
