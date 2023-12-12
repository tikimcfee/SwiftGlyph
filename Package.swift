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
            name: "SwiftGlyph",
            targets: ["SwiftGlyph"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tikimcfee/BitHandling.git", branch: "sgalpha-bits"),
        .package(url: "https://github.com/ChimeHQ/Neon.git", branch: "main"),
        .package(url: "https://github.com/alex-pinkus/tree-sitter-swift.git", branch: "with-generated-files"),
        .package(url: "https://github.com/tikimcfee/MetalLink.git", branch: "sgalpha-metal-link"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGlyph",
            dependencies: [
                "BitHandling",
                "MetalLink",
                "Neon",
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift")
            ]
        ),
        .testTarget(
            name: "SwiftGlyphTests",
            dependencies: [
                "SwiftGlyph",
                "BitHandling",
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift")
            ]
        ),
    ]
)
