// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mac2imgurCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        )
    ]
)
