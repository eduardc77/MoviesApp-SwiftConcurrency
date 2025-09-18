// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesDesignSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesDesignSystem",
            targets: ["MoviesDesignSystem"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(path: "../MoviesDomain"),
        .package(path: "../MoviesNetwork")
    ],
    targets: [
        .target(
            name: "MoviesDesignSystem",
            dependencies: [
                "Kingfisher",
                "MoviesDomain",
                "MoviesNetwork"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoviesDesignSystemTests",
            dependencies: [
                "MoviesDesignSystem"
            ]
        )
    ]
)
