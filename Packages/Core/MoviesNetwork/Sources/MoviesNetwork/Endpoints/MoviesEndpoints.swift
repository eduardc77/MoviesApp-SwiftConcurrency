//
//  MoviesEndpoints.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation
import SharedModels

/// Domain-specific endpoints for movie operations
/// Implements EndpointProtocol for type safety and consistency
public enum MoviesEndpoints: EndpointProtocol {
    case list(type: MovieType, page: Int)
    case discover(type: MovieType, page: Int, sortBy: String?)
    case details(id: Int)
    case search(query: String, page: Int)

    public var path: String {
        switch self {
        case .list(let type, _):
            return "movie/\(type.rawValue)"
        case .discover:
            return "discover/movie"
        case .details(let id):
            return "movie/\(id)"
        case .search:
            return "search/movie"
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case .search(let query, let page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page)),
            ]
        case .list(_, let page):
            return [URLQueryItem(name: "page", value: String(page))]
        case .discover(let type, let page, let sortBy):
            var params = [
                URLQueryItem(name: "page", value: String(page))
            ]

            // Add type-specific discover parameters
            var typeParams: [String: String] = [:]

            // Add category-specific filtering parameters
            switch type {
            case .nowPlaying:
                typeParams["release_date.lte"] = ISO8601DateFormatter().string(from: Date())
                typeParams["release_date.gte"] = "2024-01-01"
            case .popular:
                typeParams["sort_by"] = MoviesEndpoints.defaultSortForCategory(type)
            case .topRated:
                typeParams["sort_by"] = MoviesEndpoints.defaultSortForCategory(type)
                typeParams["vote_count.gte"] = "100"
            case .upcoming:
                let futureDate = Date().addingTimeInterval(30*24*60*60)
                typeParams["release_date.gte"] = ISO8601DateFormatter().string(from: Date())
                typeParams["release_date.lte"] = ISO8601DateFormatter().string(from: futureDate)
            }

            for (key, value) in typeParams {
                params.append(URLQueryItem(name: key, value: value))
            }

            // Override with custom sort if provided
            if let sortBy = sortBy {
                params = params.filter { $0.name != "sort_by" }
                params.append(URLQueryItem(name: "sort_by", value: sortBy))
            }
            return params
        default:
            return []
        }
    }
}

/// Convenience extension for creating movie endpoints
public extension MoviesEndpoints {
    /// Get the default sort order for a movie category
    /// - Parameter type: The movie category
    /// - Returns: TMDB sort parameter string
    private static func defaultSortForCategory(_ type: MovieType) -> String {
        switch type {
        case .popular:
            return "popularity.desc"
        case .topRated:
            return "vote_average.desc"
        case .nowPlaying, .upcoming:
            return "popularity.desc"  // Default to popularity for time-based categories
        }
    }
    /// Create endpoint for listing movies by type
    /// - Parameter type: The type of movies to fetch
    /// - Returns: Configured endpoint
    static func movies(type: MovieType, page: Int = 1) -> MoviesEndpoints {
        .list(type: type, page: page)
    }

    /// Create endpoint for discovering movies with server-side sorting
    /// - Parameters:
    ///   - type: The type of movies to fetch (used for filtering)
    ///   - page: Page number
    ///   - sortBy: TMDB sort parameter (optional, falls back to type-specific sorting)
    /// - Returns: Configured endpoint
    static func discoverMovies(type: MovieType, page: Int = 1, sortBy: String? = nil) -> MoviesEndpoints {
        .discover(type: type, page: page, sortBy: sortBy)
    }

    /// Create endpoint for movie details
    /// - Parameter id: Movie ID
    /// - Returns: Configured endpoint
    static func movieDetails(id: Int) -> MoviesEndpoints {
        .details(id: id)
    }

    /// Create endpoint for movie search
    /// - Parameter query: Search query
    /// - Returns: Configured endpoint
    static func searchMovies(query: String, page: Int = 1) -> MoviesEndpoints {
        .search(query: query, page: page)
    }
}
