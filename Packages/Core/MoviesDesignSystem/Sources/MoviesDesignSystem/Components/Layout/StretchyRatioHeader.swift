//
//  StretchyRatioHeader.swift
//  MoviesDesignSystem
//
//  Created by User on 9/11/25.
//

import SwiftUI

///  A reusable, ratio-driven stretchy header that anchors to the top and
///  grows when the user pulls down. No fixed heights; the base height is
///  derived from the provided aspect ratio and the container width.
public struct StretchyRatioHeader<Content: View>: View {
    private let ratio: CGFloat
    @ViewBuilder private var content: () -> Content

    /// - Parameters:
    ///   - ratio: width/height aspect ratio (e.g. 16/9)
    ///   - content: header content (usually an image)
    public init(ratio: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.ratio = ratio
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let baseHeight = width / ratio
            let frame = proxy.frame(in: .named("detailScroll"))
            let pullDown = max(0, frame.minY)

            content()
                .frame(width: width, height: baseHeight + pullDown)
                .offset(y: -pullDown)
        }
        .aspectRatio(ratio, contentMode: .fit)
    }
}
