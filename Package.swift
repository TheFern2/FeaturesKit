// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FeaturesKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FeaturesKit", targets: ["FeaturesKit"]),
    ],
    targets: [
        .target(name: "FeaturesKit"),
        .testTarget(name: "FeaturesKitTests", dependencies: ["FeaturesKit"]),
    ]
)
