//
//  HomeCategory.swift
//  MoviesHome
//
//  Created by User on 9/11/25.
//

import MoviesDesignSystem

enum HomeCategory: String, CaseIterable, Identifiable, TopFilter {
    case nowPlaying = "Now playing"
    case popular = "Popular"
    case topRated = "Top rated"
    case upcoming = "Upcoming"

    var id: String { rawValue }

    var title: String { rawValue }
}
