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
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1.git", exact: "0.19.0"),
        .package(url: "https://github.com/zeugmaster/Bech32Swift.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Bolt11",
            dependencies: [
                .product(name: "secp256k1", package: "swift-secp256k1"),
                .product(name: "Bech32Swift", package: "Bech32Swift"),
            ]),
        .testTarget(
            name: "Bolt11Tests",
            dependencies: ["Bolt11"]
        ),
    ]
)
