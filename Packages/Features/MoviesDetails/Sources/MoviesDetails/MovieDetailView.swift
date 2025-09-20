//
//  MovieDetailView.swift
//  MoviesDetails
//
//  Created by User on 9/10/25.
//

import SwiftUI
import MoviesDomain
import MoviesDesignSystem

/// Movie details view
public struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel

    public init(movieId: Int, repository: MovieRepositoryProtocol, favoriteStore: FavoritesStoreProtocol) {
        _viewModel = State(initialValue:
                            MovieDetailViewModel(
                                repository: repository,
                                favoritesStore: favoriteStore,
                                movieId: movieId
                            )
        )
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .error:
                notFoundView
            case .content(let movie):
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(for: movie)
                        content(for: movie)
                    }
                }
                .coordinateSpace(name: "detailScroll")  // Required for StretchyRatioHeader

            }
        }
        .navigationTitle(viewModel.movie?.title ?? String(localized: .DetailsL10n.title))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar { favoriteToolbar }
    }
}

// MARK: - Subviews
private extension MovieDetailView {
    func header(for movie: MovieDetails) -> some View {
        StretchyRatioHeader(ratio: 16.0/9.0) {
            Group {
                if let backdropPath = movie.backdropPath {
                    RemoteImageView(
                        movieBackdropPath: backdropPath,
                        contentMode: .fill  // Back to .fill for proper stretching
                    )
                    .clipped()  // Clip to prevent overflow
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .overlay(
            LinearGradient(colors: [.black.opacity(0.35), .clear],
                           startPoint: .bottom, endPoint: .center)
        )
    }

    func content(for movie: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImageView(
                    moviePosterPath: movie.posterPath,
                    placeholder: Image(systemName: "film"),
                    contentMode: .fill,
                    targetSize: CGSize(width: 130, height: 180)
                )
                .zIndex(1)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let tagline = movie.tagline, !tagline.isEmpty {
                        Text(tagline)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(format: String(localized: .DetailsL10n.releasedIn), movie.releaseYear))
                            .font(.headline)

                        HStack(spacing: 6) {
                            Image(ds: .star).foregroundStyle(Color.orange)
                            Text(String(format: String(localized: .DetailsL10n.ratingOutOfTen), movie.voteAverage))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(String(format: String(localized: .DetailsL10n.voteCount), Int64(movie.voteCount)))
                                .foregroundStyle(.secondary)
                        }
                        .font(.headline)
                    }

                    genresChips(for: movie)
                }
            }

            Divider()

            Text(String(format: String(localized: .DetailsL10n.releasedIn), movie.releaseYear))
                .font(.headline)

            Text(movie.overview)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    func genresChips(for movie: MovieDetails) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(movie.genres) { genre in
                    Text(genre.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .scrollTargetLayout()
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled()
    }

    @ToolbarContentBuilder
    var favoriteToolbar: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button { viewModel.toggleFavorite() } label: {
                if viewModel.isFavorite() {
                    Image(ds: .heartFill)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 20, height: 20)
                        .transition(.scale)
                } else {
                    Image(ds: .heart)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 20, height: 20)
                        .transition(.scale)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    var notFoundView: some View {
        ContentUnavailableView {
            Label(String(localized: .DetailsL10n.notFound), systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(String(localized: .DesignSystemL10n.none)) // or a dedicated details message if you add one
        } actions: {
            Button(String(localized: .DesignSystemL10n.retry)) {
                Task {
                    await viewModel.fetch()
                }
            }
            .tint(.primary)
            .buttonStyle(.bordered)
        }
    }
}
