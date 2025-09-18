//
//  SortToolbar.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI
import SharedModels

/// Generic reusable toolbar + menu for sorting any list
public struct SortToolbarModifier<Option: SortOption>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let onPresentDialog: (Option?, @escaping (Option) -> Void) -> Void
    private let currentSortOption: Option?
    private let onSelect: (Option) -> Void

    public init(
        onPresentDialog: @escaping (Option?, @escaping (Option) -> Void) -> Void,
        currentSortOption: Option?,
        onSelect: @escaping (Option) -> Void
    ) {
        self.onPresentDialog = onPresentDialog
        self.currentSortOption = currentSortOption
        self.onSelect = onSelect
    }

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if horizontalSizeClass == .regular {
                        Menu {
                            ForEach(Option.allCases) { option in
                                Button {
                                    onSelect(option)
                                } label: {
                                    HStack {
                                        Text(option.displayName)
                                        Spacer(minLength: 8)
                                        if currentSortOption?.id == option.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image("ic_sort", bundle: Bundle.module)
                        }
                    } else {
                        Button {
                            onPresentDialog(currentSortOption) { selectedOption in
                                onSelect(selectedOption)
                            }
                        } label: {
                            Image("ic_sort", bundle: Bundle.module)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
    }
}

public extension View {
    /// Attach a generic sort toolbar for any sortable content
    func sortToolbar<Option: SortOption>(
        onPresentDialog: @escaping (Option?, @escaping (Option) -> Void) -> Void,
        currentSortOption: Option?,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        self.modifier(SortToolbarModifier<Option>(
            onPresentDialog: onPresentDialog,
            currentSortOption: currentSortOption,
            onSelect: onSelect
        ))
    }
}
