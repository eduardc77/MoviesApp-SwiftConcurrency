// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesDetails",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesDetails",
            targets: ["MoviesDetails"]
        )
    ],
    dependencies: [
        .package(path: "../../Core/MoviesDomain"),
        .package(path: "../../Core/MoviesDesignSystem"),
        .package(path: "../../Core/MoviesUtilities"),
        .package(path: "../../Core/MoviesNetwork"),
        .package(path: "../../Core/MoviesData")
    ],
    targets: [
        .target(
            name: "MoviesDetails",
            dependencies: [
                "MoviesDomain",
                "MoviesDesignSystem"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoviesDetailsTests",
            dependencies: [
                "MoviesDetails",
                .product(name: "AppLog", package: "MoviesUtilities"),
                "MoviesNetwork",
                "MoviesData"
            ]
        )
    ]
)
