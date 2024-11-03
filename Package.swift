// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGlyph",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SwiftGlyph",
            targets: ["SwiftGlyph"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tikimcfee/BitHandling.git", branch: "main"),
        .package(url: "https://github.com/tikimcfee/MetalLink.git", branch: "main"),
        .package(url: "https://github.com/tikimcfee/STTextView.git", branch: "main"),
        .package(url: "https://github.com/tikimcfee/tree-sitter-swift.git", branch: "with-generated-files"),
        
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter.git", exact: "0.8.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGlyph",
            dependencies: [
                "BitHandling",
                "MetalLink",
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "SwiftTreeSitter", package: "SwiftTreeSitter"),
                .product(name: "STTextView", package: "STTextView"),
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "SwiftGlyphTests",
            dependencies: [
                "SwiftGlyph",
                "BitHandling"
            ]
        ),
    ]
)
