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
            name: "parchment",
            targets: ["ParchmentCLI"]
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
    ],
    targets: [
        .executableTarget(
            name: "Parchment",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .executableTarget(
            name: "ParchmentCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "TestParser",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            path: "Tests/TestParser"
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"],
            path: "Tests/ParchmentTests"
        ),
    ]
)