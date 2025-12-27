// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "swift-injection",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/behrang/YamlSwift", from: "3.4.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftInjection",
            dependencies: [
                .product(name: "Yaml", package: "YamlSwift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        )
    ]
)
