// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DPNetwork",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "DPNetwork",
            targets: ["DPNetwork"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/DPLibs/DPLogger-swift.git", from: "0.0.3")
    ],
    targets: [
        .target(
            name: "DPNetwork",
            dependencies: [
                .product(name: "DPLogger", package: "DPLogger-swift")
            ]
        ),
        .testTarget(
            name: "DPNetworkTests",
            dependencies: ["DPNetwork"]
        ),
    ]
)
