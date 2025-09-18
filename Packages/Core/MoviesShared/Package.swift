// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoviesShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SharedModels",
            targets: ["SharedModels"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: []
        )
    ]
)
