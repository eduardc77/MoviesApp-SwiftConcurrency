//
//  MoviePage.swift
//  MoviesDomain
//
//  Created by User on 9/14/25.
//

public struct MoviePage: Sendable {
    public let items: [Movie]
    public let page: Int
    public let totalPages: Int
    public init(items: [Movie], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }
}
