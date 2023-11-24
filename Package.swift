// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGlyphs",
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
        .package(url: "https://github.com/rapidlugo/LSPServiceKit.git", branch: "master"),
        .package(url: "https://github.com/tikimcfee/BitHandling.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/codeface-io/SwiftNodes.git", .upToNextMajor(from: "0.7.0")),
        .package(path: "../MetalLink"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGlyphs",
            dependencies: [
                "BitHandling",
                "MetalLink",
                "SwiftNodes",
                "LSPServiceKit",
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
