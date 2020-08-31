// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "PersistentState",
    products: [
        .library(
            name: "PersistentState",
            targets: ["PersistentState"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PersistentState",
            dependencies: []),
        .testTarget(
            name: "PersistentStateTests",
            dependencies: ["PersistentState"])
    ]
)
