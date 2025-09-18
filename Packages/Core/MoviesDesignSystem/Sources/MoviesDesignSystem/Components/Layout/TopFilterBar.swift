//
//  TopFilterBar.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI

public protocol TopFilter: Hashable, CaseIterable, Identifiable {
    var title: String { get }
}

public struct TopFilterBar<T: TopFilter>: View {
    @Binding private var currentFilter: T
    private var onSelection: (() -> Void)?

    private let activeColor: Color
    private let inactiveColor: Color
    private let underlineColor: Color

    @Namespace private var animation

    public init(
        currentFilter: Binding<T>,
        activeColor: Color = .primary,
        inactiveColor: Color = .secondary,
        underlineColor: Color = .primary,
        onSelection: (() -> Void)? = nil
    ) {
        self._currentFilter = currentFilter
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.underlineColor = underlineColor
        self.onSelection = onSelection
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(Array(T.allCases)) { filter in
                        filterItem(for: filter)
                    }
                }
                .padding(.horizontal)

            }
            Divider().opacity(0.15)
        }
    }

    private func filterItem(for filter: T) -> some View {
        Button {
            onSelection?()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                currentFilter = filter
            }
        } label: {
            Text(filter.title)
                .lineLimit(1)
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.bottom, 5)
                .foregroundStyle(currentFilter == filter ? activeColor : inactiveColor)
                .overlay(alignment: .bottom) {
                    if currentFilter == filter {
                        Rectangle()
                            .fill(underlineColor)
                            .frame(height: 4)
                            .matchedGeometryEffect(id: "TopFilterBar", in: animation)
                    }
                }
        }
        .buttonStyle(.borderless)
    }
}
