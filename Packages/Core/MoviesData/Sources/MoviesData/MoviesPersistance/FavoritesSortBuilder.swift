//
//  FavoritesSortBuilder.swift
//  MoviesData
//
//  Created by User on 9/21/25.
//

import Foundation
import SwiftData
import MoviesDomain

enum FavoritesSortBuilder {
    static func descriptors(for sortOrder: MovieSortOrder?) -> [SortDescriptor<FavoriteMovieEntity>] {
        var sortDescriptors: [SortDescriptor<FavoriteMovieEntity>] = []
        if let order = sortOrder {
            switch order {
            case .popularityAscending:
                sortDescriptors.append(SortDescriptor(\.popularity, order: .forward))
            case .popularityDescending:
                sortDescriptors.append(SortDescriptor(\.popularity, order: .reverse))
            case .ratingAscending:
                sortDescriptors.append(SortDescriptor(\.voteAverage, order: .forward))
            case .ratingDescending:
                sortDescriptors.append(SortDescriptor(\.voteAverage, order: .reverse))
            case .releaseDateAscending:
                sortDescriptors.append(SortDescriptor(\.releaseDate, order: .forward))
            case .releaseDateDescending:
                sortDescriptors.append(SortDescriptor(\.releaseDate, order: .reverse))
            case .recentlyAdded:
                sortDescriptors.append(SortDescriptor(\.createdAt, order: .reverse))
            }
        } else {
            sortDescriptors.append(SortDescriptor(\.createdAt, order: .reverse))
        }
        // Deterministic tie-breaker
        sortDescriptors.append(SortDescriptor(\.movieId, order: .forward))
        return sortDescriptors
    }
}


