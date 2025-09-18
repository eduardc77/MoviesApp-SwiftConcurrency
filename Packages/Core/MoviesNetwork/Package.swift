// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesNetwork",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesNetwork",
            targets: ["MoviesNetwork"]
        )
    ],
    dependencies: [
        .package(path: "../MoviesShared"),
        .package(path: "../MoviesUtilities")
    ],
    targets: [
        .target(
            name: "MoviesNetwork",
            dependencies: [
                .product(name: "SharedModels", package: "MoviesShared"),
                .product(name: "AppLog", package: "MoviesUtilities")
            ]
        ),
        .testTarget(
            name: "MoviesNetworkTests",
            dependencies: ["MoviesNetwork"]
        )
    ]
)
