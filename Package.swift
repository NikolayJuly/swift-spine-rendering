// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "spine-swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v14),
    ],
    products: [
        .library(name: "SpineSwift", targets: ["SpineSwift", "SpineC"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
    ],
    targets: [
        .target(name: "FoundationExtension"),
        .target(
            name: "MetalExtension",
            dependencies: [
                "FoundationExtension",
            ]
        ),
        .target(
            name: "SpineC",
            publicHeadersPath: "include"),
        .target(
            name: "SpineC-SwiftImpl",
            dependencies: [
                "SpineC",
            ]
        ),
        .target(
            name: "SpineSwift",
            dependencies: [
                "FoundationExtension",
                "MetalExtension",
                "SpineC",
                "SpineC-SwiftImpl",
                "SpineSharedStructs",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .systemLibrary(name: "SpineSharedStructs")

    ]
)
