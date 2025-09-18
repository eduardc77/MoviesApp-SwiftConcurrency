//
//  NavigationDestinations.swift
//  MoviesNavigation
//
//  Created by User on 9/10/25.
//

import MoviesDomain

/// Main app navigation destinations
public enum AppDestination: Hashable {
    case movieDetails(id: Int)
}

/// Movie details destinations (for nested navigation)
public enum MovieDetailsDestination: Hashable {
    case cast
    case reviews
    case similarMovies
    case movieDetails(Movie) // For similar movies navigation
}

/// Navigation context for coordinating between features
public enum NavigationContext {
    case search
    case home
    case favorites
}

/// Deep link types for the app
public enum AppDeepLink {
    case movieDetails(Int) // movie ID
    case search(String) // search query
    case tab(AppTab) // specific tab
}

/// Result of processing a deep link
public enum DeepLinkResult {
    case navigateToMovie(Int)
    case navigateToSearch(String)
    case switchToTab(AppTab)
    case invalid
}
