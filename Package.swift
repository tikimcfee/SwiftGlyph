// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGlyph",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "SwiftGlyphs",
            targets: ["SwiftGlyphs"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tikimcfee/BitHandling.git", branch: "sgalpha-bits"),
        .package(url: "https://github.com/tikimcfee/MetalLink.git", branch: "sgalpha-metal-link"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGlyphs",
            dependencies: [
                "BitHandling",
                "MetalLink",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SwiftGlyphsTests",
            dependencies: [
                "SwiftGlyphs",
                "BitHandling",
            ]
        ),
    ]
)
