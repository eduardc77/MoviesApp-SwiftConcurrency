//
//  MoviesApp.swift
//  Movies
//
//  Created by User on 9/18/25.
//

import SwiftUI
import MoviesDesignSystem
import AppLog
import MoviesNavigation

@main
struct MoviesApp: App {
    /// Main dependency injection container
    private let appEnvironment: AppDependencies
    /// Main app router for navigation
    private let appRouter: AppRouter

    init() {
        // Configure Kingfisher
        KingfisherConfig.configure()
        // Configure global navigation/tab, search, and alert appearance
        NavigationAppearance.configure()
        SearchBarAppearance.configure()
        AlertAppearance.configure()

        self.appEnvironment = AppDependencies()

        // Initialize app router
        self.appRouter = AppRouter()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appRouter)
                .environment(appEnvironment)
        }
    }
}
