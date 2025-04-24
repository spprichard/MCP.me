// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCP.me",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // 🚜 Executable
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // 🤖 SwiftMCP
        .package(url: "https://github.com/Cocoanetics/SwiftMCP", branch: "main"),
        // ✉️ Email
         .package(url: "https://github.com/Cocoanetics/SwiftMail", branch: "main"),
        // .package(path: "../SwiftMail"),
        .package(url: "https://github.com/thebarndog/swift-dotenv", from: "2.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "MCP.me",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
