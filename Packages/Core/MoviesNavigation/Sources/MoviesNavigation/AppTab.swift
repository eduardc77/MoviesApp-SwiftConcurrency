//
//  AppTab.swift
//  MoviesNavigation
//
//  Created by User on 9/11/25.
//

/// App tabs for the Movies app
public enum AppTab: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case search = 0
    case home = 1
    case favorites = 2

    public var id: AppTab { self }

    public var title: String {
        switch self {
        case .search: return "Search"
        case .home: return "Home"
        case .favorites: return "Favorites"
        }
    }

    public var systemImage: String {
        switch self {
        case .search: return "ic_search"
        case .home: return "ic_home"
        case .favorites: return "ic_favorites"
        }
    }
}
