// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "mdview",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mdview", targets: ["MDView"])
    ],
    targets: [
        .executableTarget(name: "MDView"),
        .testTarget(name: "MDViewTests", dependencies: ["MDView"])
    ]
)
