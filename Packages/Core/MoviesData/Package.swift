// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesData",
            targets: ["MoviesData"]
        )
    ],
    dependencies: [
        .package(path: "../MoviesShared"),
        .package(path: "../MoviesDomain"),
        .package(path: "../MoviesNetwork"),
        .package(path: "../MoviesUtilities")
    ],
    targets: [
        .target(
            name: "MoviesData",
            dependencies: [
                .product(name: "SharedModels", package: "MoviesShared"),
                "MoviesDomain",
                "MoviesNetwork",
                .product(name: "AppLog", package: "MoviesUtilities")
            ]
        ),
        .testTarget(
            name: "MoviesDataTests",
            dependencies: ["MoviesData"]
        )
    ]
)
