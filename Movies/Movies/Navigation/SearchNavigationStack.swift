//
//  SearchNavigationStack.swift
//  Movies
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation
import MoviesSearch

/// Navigation stack for the Search tab
public struct SearchNavigationStack: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppDependencies.self) private var appDependencies

    public init() {}

    public var body: some View {
        @Bindable var appRouter = appRouter
        NavigationStack(path: $appRouter.searchPath) {
            SearchView(repository: appDependencies.movieRepository, favoriteStore: appDependencies.favorites)
                .withAppDestinations()

        }
    }
}
