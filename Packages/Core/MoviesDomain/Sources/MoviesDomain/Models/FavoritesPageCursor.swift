//
//  FavoritesPageCursor.swift
//  MoviesDomain
//
//  Created by User on 9/21/25.
//

import Foundation

/// Cursor for keyset pagination over favorites (type-safe per sort)
public enum FavoritesPageCursor: Sendable, Equatable, Hashable {
    case recentlyAdded(lastCreatedAt: Date, lastMovieId: Int)
    case ratingDescending(lastVoteAverage: Double, lastMovieId: Int)
    case ratingAscending(lastVoteAverage: Double, lastMovieId: Int)
    case releaseDateDescending(lastDate: String, lastMovieId: Int)
    case releaseDateAscending(lastDate: String, lastMovieId: Int)
}


