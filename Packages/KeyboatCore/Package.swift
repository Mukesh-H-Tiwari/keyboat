// swift-tools-version: 5.9
// KeyboatCore — dependency-free business logic shared by App + Extension.
// NO UIKit. Foundation + NaturalLanguage + Combine only.

import PackageDescription

let package = Package(
    name: "KeyboatCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v12),   // needed for swift test on macOS host (Combine availability)
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "KeyboatCore",
            targets: ["KeyboatCore"]
        )
    ],
    targets: [
        .target(
            name: "KeyboatCore",
            path: "Sources/KeyboatCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "KeyboatCoreTests",
            dependencies: ["KeyboatCore"],
            path: "Tests/KeyboatCoreTests"
        )
    ]
)
