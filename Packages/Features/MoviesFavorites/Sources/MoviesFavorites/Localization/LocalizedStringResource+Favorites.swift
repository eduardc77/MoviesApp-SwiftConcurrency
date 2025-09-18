//
//  LocalizedStringResource+Favorites.swift
//  MoviesFavorites
//
//  Created by User on 9/10/25.
//

import Foundation

public extension LocalizedStringResource {
    enum FavoritesL10n {
        public static let title = LocalizedStringResource("favorites.title", table: "Favorites", bundle: .atURL(Bundle.module.bundleURL))
        public static let emptyTitle = LocalizedStringResource("favorites.empty_title", table: "Favorites", bundle: .atURL(Bundle.module.bundleURL))
        public static let emptyDescription = LocalizedStringResource("favorites.empty_description", table: "Favorites", bundle: .atURL(Bundle.module.bundleURL))
        public static let errorTitle = LocalizedStringResource("favorites.error_title", table: "Favorites", bundle: .atURL(Bundle.module.bundleURL))
    }
}
