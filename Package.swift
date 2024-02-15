// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SentryVapor",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SentryVapor",
            targets: ["SentryVapor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Blindspot-cloud/sentry-swift.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SentryVapor",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SentrySwift", package: "sentry-swift")
            ]
        )
    ]
)
