// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ValueProvider",
    products: [
        .library(
            name: "ValueProvider",
            targets: ["ValueProvider"]),
        .library(
            name: "FilesystemValueProvider",
            targets: ["FilesystemValueProvider"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ValueProvider",
            dependencies: []),
        .target(
            name: "FilesystemValueProvider",
            dependencies: ["ValueProvider"]),
        .testTarget(
            name: "FilesystemValueProviderTests",
            dependencies: ["ValueProvider", "FilesystemValueProvider"])
    ]
)
