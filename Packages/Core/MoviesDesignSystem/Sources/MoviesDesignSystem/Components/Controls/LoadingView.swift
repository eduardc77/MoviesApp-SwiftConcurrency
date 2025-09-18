//
//  LoadingView.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI

/// A reusable loading view component with consistent styling
public struct LoadingView: View {
    /// The text to display below the progress indicator
    public let text: LocalizedStringResource?

    /// The scale of the progress indicator (default: 1.2)
    public let scale: CGFloat

    /// Initialize with custom text
    /// - Parameters:
    ///   - text: The localized text to display (defaults to design system loading text)
    ///   - scale: Scale of the progress indicator (default: 1.2)
    public init(
        _ text: LocalizedStringResource? = nil,
        scale: CGFloat = 1.2
    ) {
        self.text = text ?? .DesignSystemL10n.loading
        self.scale = scale
    }

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(scale)
            if let text {
                Text(String(localized: text))
                    .font(.subheadline)
            }
        }
        .tint(Color.primary)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.4))
    }
}

#Preview {
    LoadingView()
}
