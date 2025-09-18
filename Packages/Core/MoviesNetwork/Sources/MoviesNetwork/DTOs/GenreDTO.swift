//
//  GenreDTO.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

/// Data Transfer Object for genre data
public struct GenreDTO: Decodable, Identifiable, Hashable, Equatable {
    public let id: Int
    public let name: String
}
