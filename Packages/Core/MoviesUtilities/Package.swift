// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoviesUtilities",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "AppLog",
            targets: ["AppLog"]
        ),
        .library(
            name: "DateUtilities",
            targets: ["DateUtilities"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AppLog",
            path: "Sources/AppLog"
        ),
        .target(
            name: "DateUtilities",
            path: "Sources/DateUtilities"
        ),
        .testTarget(
            name: "DateUtilitiesTests",
            dependencies: ["DateUtilities"]
        ),
    ]
)
