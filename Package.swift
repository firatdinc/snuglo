// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnugloEngine",
    platforms: [.iOS(.v17), .macOS(.v13)], // macOS: swift test için
    products: [
        .library(name: "SnugloEngine", targets: ["SnugloEngine"])
    ],
    targets: [
        .target(
            name: "SnugloEngine",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SnugloEngineTests",
            dependencies: ["SnugloEngine"]
        )
    ]
)
