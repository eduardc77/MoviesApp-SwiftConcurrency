//
//  FavoritesNavigationStack.swift
//  Movies
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation
import MoviesFavorites

/// Navigation stack for the Favorites tab
public struct FavoritesNavigationStack: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppDependencies.self) private var appDependencies

    public init() {}

    public var body: some View {
        @Bindable var appRouter = appRouter
        NavigationStack(path: $appRouter.favoritesPath) {
            FavoritesView(repository: appDependencies.movieRepository, favoriteStore: appDependencies.favorites)
                .withAppDestinations()
        }
    }
}
