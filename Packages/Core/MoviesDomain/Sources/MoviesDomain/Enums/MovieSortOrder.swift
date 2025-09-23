//
//  MovieSortOrder.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import Foundation
import SharedModels

/// Canonical sort orders supported by the app for movie lists
public enum MovieSortOrder: String, CaseIterable, Identifiable, Sendable, SortOption {
    case popularityAscending
    case popularityDescending
    case ratingAscending
    case ratingDescending
    case releaseDateAscending
    case releaseDateDescending
    case recentlyAdded

    public var id: String { rawValue }

    /// Localized display title used by UI
    public var labelKey: LocalizedStringResource {
        switch self {
        case .popularityAscending: return .DomainL10n.popularityAscending
        case .popularityDescending: return .DomainL10n.popularityDescending
        case .ratingAscending: return .DomainL10n.ratingAscending
        case .ratingDescending: return .DomainL10n.ratingDescending
        case .releaseDateAscending: return .DomainL10n.releaseDateAscending
        case .releaseDateDescending: return .DomainL10n.releaseDateDescending
        case .recentlyAdded: return .DomainL10n.recentlyAdded
        }
    }

    /// Display name for the SortOption protocol
    public var displayName: String {
        String(localized: labelKey)
    }

    /// TMDB server-side sort parameter value for endpoints that support it
    /// Note: recentlyAdded is only used for favorites, not TMDB API
    public var tmdbSortValue: String {
        switch self {
        case .popularityAscending: return "popularity.asc"
        case .popularityDescending: return "popularity.desc"
        case .ratingAscending: return "vote_average.asc"
        case .ratingDescending: return "vote_average.desc"
        case .releaseDateAscending: return "release_date.asc"
        case .releaseDateDescending: return "release_date.desc"
        case .recentlyAdded:
            // This should never be called for TMDB API, but provide a fallback
            return "popularity.desc"
        }
    }
}

public extension Array where Element == Movie {
    /// Returns a new array sorted by the provided order
    func sorted(by order: MovieSortOrder) -> [Movie] {
        switch order {
        case .popularityAscending:
            return self.sorted { $0.popularity < $1.popularity }
        case .popularityDescending:
            return self.sorted { $0.popularity > $1.popularity }
        case .ratingAscending:
            return self.sorted { $0.voteAverage < $1.voteAverage }
        case .ratingDescending:
            return self.sorted { $0.voteAverage > $1.voteAverage }
        case .releaseDateAscending:
            // Dates are ISO-8601 (YYYY-MM-DD) so lexical compare is fine
            return self.sorted { $0.releaseDate < $1.releaseDate }
        case .releaseDateDescending:
            return self.sorted { $0.releaseDate > $1.releaseDate }
        case .recentlyAdded:
            // recentlyAdded is only meaningful for favorites with createdAt timestamps
            // For general movie arrays, return unsorted
            return self
        }
    }
}
