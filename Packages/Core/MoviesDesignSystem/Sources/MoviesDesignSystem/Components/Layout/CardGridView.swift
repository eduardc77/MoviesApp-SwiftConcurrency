//
//  CardGridView.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI

/// Reusable grid for displaying CardDisplayable items using GenericCardView
public struct CardGridView<Item: CardDisplayable>: View {
    private let items: [Item]
    private let onTap: (Item) -> Void
    private let onFavoriteToggle: (Item) -> Void
    private let isFavorite: (Item) -> Bool
    private let onLoadNext: (() -> Void)?
    private let showLoadingOverlay: Bool
    private let onRefresh: (() async -> Void)?
    @Binding private var shouldScrollToTop: Bool

    @State private var hasTriggeredLoadNext = false
    @State private var hasScrolledToTop = false

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 8, alignment: .top)
    ]

    public init(
        items: [Item],
        onTap: @escaping (Item) -> Void,
        onFavoriteToggle: @escaping (Item) -> Void,
        isFavorite: @escaping (Item) -> Bool,
        onLoadNext: (() -> Void)? = nil,
        showLoadingOverlay: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        shouldScrollToTop: Binding<Bool> = .constant(false)
    ) {
        self.items = items
        self.onTap = onTap
        self.onFavoriteToggle = onFavoriteToggle
        self.isFavorite = isFavorite
        self.onLoadNext = onLoadNext
        self.showLoadingOverlay = showLoadingOverlay
        self.onRefresh = onRefresh
        self._shouldScrollToTop = shouldScrollToTop
    }

    public var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(items, id: \.idKey) { item in
                        GenericCardView(
                            item: item,
                            onTap: { onTap(item) },
                            onFavoriteToggle: { onFavoriteToggle(item) },
                            isFavorite: { isFavorite(item) }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .onAppear {
                            if let index = items.firstIndex(where: { $0.idKey == item.idKey }),
                               index >= items.count - UIScrollingDefaults.gridPrefetchThreshold && !hasTriggeredLoadNext {
                                hasTriggeredLoadNext = true
                                onLoadNext?()
                            }
                        }
                    }
                }
                .animation(.spring(duration: 0.4, bounce: 0.2), value: items.map(\.idKey))
                .padding(10)
                .id("grid-top") // Anchor for scroll-to-top

                if showLoadingOverlay {
                    footerLoadingIndicator
                }
            }
            .refreshable {
                if let onRefresh {
                    await onRefresh()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: items.count) { _, _ in
                hasTriggeredLoadNext = false // Reset when items count changes
            }
            .onChange(of: shouldScrollToTop) { _, shouldScroll in
                if shouldScroll && !hasScrolledToTop {
                    hasScrolledToTop = true
                    // Defer to next runloop so grid updates (new sort/page 1) are applied
                    DispatchQueue.main.async {
                        scrollProxy.scrollTo("grid-top", anchor: .top)
                        // Reset flags after scrolling
                        hasScrolledToTop = false
                        hasTriggeredLoadNext = false
                        shouldScrollToTop = false
                    }
                }
            }
            .background(Color.secondary.opacity(0.4))
        }
    }

    var footerLoadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text(.DesignSystemL10n.loadingMore)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
// Helper to access id property without requiring Identifiable conformance
private extension CardDisplayable {
    var idKey: Int { id }
}
