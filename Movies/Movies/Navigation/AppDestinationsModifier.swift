//
//  AppDestinationsModifier.swift
//  Movies
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation
import MoviesDetails

/// Attaches app-wide destinations once, to avoid duplicated switches in stacks
struct AppDestinationsModifier: ViewModifier {
    @Environment(AppDependencies.self) private var appEnvironment

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .movieDetails(let id):
                    MovieDetailView(
                        movieId: id,
                        repository: appEnvironment.movieRepository,
                        favoriteStore: appEnvironment.favorites
                    )
                }
            }
    }
}

extension View {
    /// Registers app-wide destinations using the app environment
    func withAppDestinations() -> some View {
        modifier(AppDestinationsModifier())
    }
}
