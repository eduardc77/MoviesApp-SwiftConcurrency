//
//  SortOption.swift
//  MoviesShared
//
//  Created by User on 9/16/25.
//

/// Protocol for any sortable option that can be displayed in a sort toolbar
public protocol SortOption: Identifiable, CaseIterable where AllCases: RandomAccessCollection {
    var displayName: String { get }
}
