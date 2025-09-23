//
//  DialogPresenter.swift
//  Movies
//
//  Created by User on 9/16/25.
//

import SwiftUI
import MoviesNavigation
import MoviesDomain
import MoviesDesignSystem

struct DialogPresenter: ViewModifier {
    @Environment(AppRouter.self) private var appRouter

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                String(localized: .DesignSystemL10n.sortTitle),
                isPresented: .init(
                    get: { appRouter.dialog != .none },
                    set: { if !$0 { appRouter.dismissDialog() } }
                ),
                titleVisibility: .visible
            ) {
                if case .sortOptions(let available, let current, let onSelect) = appRouter.dialog {
                    sortDialogContent(available: available, current: current, onSelect: onSelect)
                }
            }
    }

    @ViewBuilder
    private func sortDialogContent(available: [MovieSortOrder], current: MovieSortOrder?, onSelect: @escaping (MovieSortOrder) -> Void) -> some View {
        ForEach(available, id: \.id) { option in
            Button {
                onSelect(option)
                appRouter.dismissDialog()
            } label: {
                Text("\(current?.id == option.id ? "✓" : "") \(option.displayName)")

            }
            .tint(Color.primary)
        }

        Button(String(localized: .DesignSystemL10n.cancel), role: .cancel) {
            appRouter.dismissDialog()
        }
    }
}

extension View {
    /// Adds app-level dialog presentation
    func withDialogs() -> some View {
        modifier(DialogPresenter())
    }
}
