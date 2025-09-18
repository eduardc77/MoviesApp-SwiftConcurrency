//
//  RemoteImageView.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI
import Kingfisher
import MoviesNetwork

/// Simple, performant remote image view using Kingfisher
public struct RemoteImageView: View {
    private let url: URL?
    private let placeholder: SwiftUI.Image
    private let contentMode: SwiftUI.ContentMode
    private let targetSize: CGSize?

    public init(
        url: URL?,
        placeholder: SwiftUI.Image = SwiftUI.Image(systemName: "photo"),
        contentMode: SwiftUI.ContentMode = .fit,
        targetSize: CGSize? = nil
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.targetSize = targetSize
    }

    public var body: some View {
        let image = KFImage(url)
            .placeholder {
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .overlay(
                        placeholder
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .setProcessor(DownsamplingImageProcessor(size: targetSize ?? CGSize(width: 300, height: 300)))
            .fade(duration: 0.2)
            .cancelOnDisappear(true)
            .cacheOriginalImage()
            .resizable()
            .aspectRatio(contentMode: contentMode)

        if let targetSize {
            image
                .frame(width: targetSize.width, height: targetSize.height)
        } else {
            image
        }
    }
}

// MARK: - Convenience Initializers

public extension RemoteImageView {
    /// RemoteImageView with Color placeholder
    init(
        url: URL?,
        placeholderColor: SwiftUI.Color = .gray.opacity(0.3),
        contentMode: SwiftUI.ContentMode = .fit,
        targetSize: CGSize? = nil
    ) {
        self.init(
            url: url,
            placeholder: SwiftUI.Image(systemName: "photo"),
            contentMode: contentMode,
            targetSize: targetSize
        )
    }
}

// MARK: - Movie-Specific Extensions

public extension RemoteImageView {
    /// RemoteImageView for movie poster using MovieImageHelper
    init(
        moviePosterPath: String?,
        config: NetworkingConfig = TMDBNetworkingConfig.config,
        placeholder: SwiftUI.Image = SwiftUI.Image(systemName: "film"),
        contentMode: SwiftUI.ContentMode = .fit,
        targetSize: CGSize? = nil
    ) {
        let imageHelper = MovieImageHelper(config: config)
        let url = imageHelper.posterURL(posterPath: moviePosterPath)

        self.init(
            url: url,
            placeholder: placeholder,
            contentMode: contentMode,
            targetSize: targetSize
        )
    }

    /// RemoteImageView for movie backdrop using MovieImageHelper
    init(
        movieBackdropPath: String?,
        config: NetworkingConfig = TMDBNetworkingConfig.config,
        placeholder: SwiftUI.Image = SwiftUI.Image(systemName: "photo"),
        contentMode: SwiftUI.ContentMode = .fit,
        targetSize: CGSize? = nil
    ) {
        let imageHelper = MovieImageHelper(config: config)
        let url = imageHelper.backdropURL(backdropPath: movieBackdropPath)

        self.init(
            url: url,
            placeholder: placeholder,
            contentMode: contentMode,
            targetSize: targetSize
        )
    }
}
