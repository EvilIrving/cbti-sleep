// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoEditor",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VideoEditor",
            targets: ["VideoEditor"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "VideoEditor",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "VideoEditorTests",
            dependencies: ["VideoEditor"],
            path: "Tests"
        ),
    ]
)
