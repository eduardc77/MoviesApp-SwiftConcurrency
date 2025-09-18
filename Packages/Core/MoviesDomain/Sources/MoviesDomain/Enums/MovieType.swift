//
//  MovieType+Domain.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import Foundation
import SharedModels

// Domain-specific extensions to the shared MovieType
extension MovieType {

    public var labelKey: LocalizedStringResource {
        switch self {
        case .nowPlaying: return .DomainL10n.nowPlaying
        case .popular: return .DomainL10n.popular
        case .topRated: return .DomainL10n.topRated
        case .upcoming: return .DomainL10n.upcoming
        }
    }
}
