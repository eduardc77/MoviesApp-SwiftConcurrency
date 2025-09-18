//
//  MovieType.swift
//  MoviesShared
//
//  Created by User on 9/16/25.
//

/// Core movie category enum shared across all layers
/// Contains the fundamental business concept of movie categories
public enum MovieType: String, CaseIterable, Sendable {
    case nowPlaying = "now_playing"
    case popular
    case topRated = "top_rated"
    case upcoming
}
