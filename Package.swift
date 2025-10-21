// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bolt11",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Bolt11",
            targets: ["Bolt11"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", from: "0.17.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Bolt11",
            dependencies: [
                .product(name: "libsecp256k1", package: "secp256k1.swift"),
            ]),
        .testTarget(
            name: "Bolt11Tests",
            dependencies: ["Bolt11"]
        ),
    ]
)
