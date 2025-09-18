//
//  AppTabView.swift
//  Movies
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesNavigation

/// Main tab view for the Movies app
public struct AppTabView: View {
    @Environment(AppRouter.self) private var appRouter

    public init() {}

    public var body: some View {
        @Bindable var appRouter = appRouter
        TabView(selection: $appRouter.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tab.destination()
                    .tag(tab)
                    .tabItem { tab.label }
            }
        }
        .tint(.white)
    }
}

// MARK: - Tab Destination Extensions
@MainActor
extension MoviesNavigation.AppTab {
    @ViewBuilder
    public func destination() -> some View {
        switch self {
        case .search:
            SearchNavigationStack()
        case .home:
            HomeNavigationStack()
        case .favorites:
            FavoritesNavigationStack()
        }
    }

    public var label: some View {
        Label(title, image: systemImage)
    }
}
