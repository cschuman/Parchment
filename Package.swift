// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Parchment",
            targets: ["Parchment"]
        ),
        .executable(
            name: "TestMarkdownKit",
            targets: ["TestMarkdownKit"]
        ),
        .executable(
            name: "TestParser",
            targets: ["TestParser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/objecthub/swift-markdownkit.git", from: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "Parchment",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "MarkdownKit", package: "swift-markdownkit"),
            ]
        ),
        .executableTarget(
            name: "TestMarkdownKit",
            dependencies: [
                .product(name: "MarkdownKit", package: "swift-markdownkit"),
            ]
        ),
        .executableTarget(
            name: "TestParser",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"],
            path: "Tests/ParchmentTests"
        ),
    ]
)