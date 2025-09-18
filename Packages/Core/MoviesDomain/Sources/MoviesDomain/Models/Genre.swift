//
//  Genre.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

public struct Genre: Identifiable, Hashable, Equatable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
