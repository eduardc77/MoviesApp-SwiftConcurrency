// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MoviesDomain",
            targets: ["MoviesDomain"]
        ),
    ],
    dependencies: [
        .package(path: "../MoviesShared"),
        .package(path: "../MoviesUtilities"),
    ],
    targets: [
        .target(
            name: "MoviesDomain",
            dependencies: [
                .product(name: "SharedModels", package: "MoviesShared"),
                .product(name: "DateUtilities", package: "MoviesUtilities")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoviesDomainTests",
            dependencies: ["MoviesDomain"]
        ),
    ]
)
