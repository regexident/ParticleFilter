// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParticleFilter",
    products: [
        .library(
            name: "ParticleFilter",
            targets: [
                "ParticleFilter",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/regexident/BayesFilter", .branch("master")),
        .package(url: "https://github.com/regexident/StateSpaceModel", .branch("master")),
        .package(url: "https://github.com/jounce/Surge", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "ParticleFilter",
            dependencies: [
                "BayesFilter",
                "StateSpaceModel",
                "Surge",
            ]
        ),
        .testTarget(
            name: "ParticleFilterTests",
            dependencies: [
                "ParticleFilter",
            ]
        ),
    ]
)
