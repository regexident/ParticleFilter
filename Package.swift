// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParticleFilter",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_11),
    ],
    products: [
        .library(
            name: "ParticleFilter",
            targets: ["ParticleFilter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/Surge.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(name: "particle_filter", dependencies: []),
        .target(
            name: "ParticleFilter",
            dependencies: [
                "particle_filter",
                "Surge",
            ]
        ),
        .testTarget(
            name: "ParticleFilterTests",
            dependencies: ["ParticleFilter"]
        ),
    ]
)
