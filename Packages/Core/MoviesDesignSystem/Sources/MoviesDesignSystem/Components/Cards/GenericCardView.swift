//
//  GenericCardView.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI

/// Protocol for items that can be displayed in a card format
public protocol CardDisplayable {
    var id: Int { get }
    var title: String { get }
    var posterPath: String? { get }
    var releaseYear: String { get }
    var rating: Double { get }
}

/// Generic card view that can display any CardDisplayable item
public struct GenericCardView<Item: CardDisplayable>: View {
    let item: Item
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    let isFavorite: () -> Bool

    public init(
        item: Item,
        onTap: @escaping () -> Void,
        onFavoriteToggle: @escaping () -> Void,
        isFavorite: @escaping () -> Bool
    ) {
        self.item = item
        self.onTap = onTap
        self.onFavoriteToggle = onFavoriteToggle
        self.isFavorite = isFavorite
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster: fixed 2:3 box so placeholder never affects width
                ZStack { Color.clear }
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay(
                        RemoteImageView(
                            moviePosterPath: item.posterPath,
                            placeholder: Image(systemName: "film"),
                            contentMode: .fill,
                            targetSize: nil
                        )
                        .clipped()
                    )
                    .clipShape(.rect(cornerRadius: 6))
                    .padding(.horizontal, 3)
                    .padding(.top, 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.separator, lineWidth: 0.5)
                    )

                HStack(alignment: .center) {
                    Text(item.releaseYear)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        Image(ds: .star)
                            .renderingMode(.template)
                            .foregroundStyle(.orange)
                        Text("\(item.rating, specifier: "%.1f")")
                            .lineLimit(1)
                            .font(.footnote.weight(.semibold))
                    }

                    Spacer(minLength: 0)

                    Button(action: onFavoriteToggle) {
                        if isFavorite() {
                            Image(ds: .heartFill)
                                .renderingMode(.original)
                                .transition(.scale)
                        } else {
                            Image(ds: .heart)
                                .renderingMode(.template)
                                .foregroundStyle(.primary)
                                .transition(.scale)

                        }
                    }
                    .frame(width: 20, height: 20)
                    .buttonStyle(.plain)
                }
                .padding()
                .animation(.default, value: isFavorite())
            }
        }
        .buttonStyle(.plain)
        .background()
        .clipShape(.rect(cornerRadius: 6))
        .contentShape(.rect)
    }
}

// MARK: - Protocol Conformance

import MoviesDomain

extension Movie: CardDisplayable {
    public var rating: Double { voteAverage }
}
