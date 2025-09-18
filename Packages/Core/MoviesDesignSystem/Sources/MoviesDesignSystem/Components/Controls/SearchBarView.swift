//
//  SearchBarView.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

// Dropped the custom SearchBar in favor of the native .searchable modifier.
import SwiftUI

/// Lightweight, customizable search bar matching the evaluation mock
public struct SearchBarView: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        placeholder: String = String(localized: .DesignSystemL10n.searchPlaceholder),
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(ds: .magnifier)
                .renderingMode(.template)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled(true)
                .focused($isFocused)
                #if os(iOS)
                .submitLabel(.search)
                #endif
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel(String(localized: .DesignSystemL10n.searchClearA11y))
            }
        }
        .padding(5)
        .background(Color.secondary.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                #if canImport(UIKit)
                .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
                #else
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                #endif
        )
    }
}
