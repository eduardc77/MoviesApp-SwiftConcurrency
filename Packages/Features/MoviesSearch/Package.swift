// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesSearch",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesSearch",
            targets: ["MoviesSearch"]
        )
    ],
    dependencies: [
        .package(path: "../../Core/MoviesDomain"),
        .package(path: "../../Core/MoviesShared"),
        .package(path: "../../Core/MoviesData"),
        .package(path: "../../Core/MoviesNavigation"),
        .package(path: "../../Core/MoviesDesignSystem")
    ],
    targets: [
        .target(
            name: "MoviesSearch",
            dependencies: [
                .product(name: "SharedModels", package: "MoviesShared"),
                "MoviesDomain",
                "MoviesData",
                "MoviesNavigation",
                "MoviesDesignSystem"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoviesSearchTests",
            dependencies: ["MoviesSearch"]
        )
    ]
)
