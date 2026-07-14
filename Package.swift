// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DockShelf",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DockShelf", targets: ["DockShelf"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.4")
    ],
    targets: [
        .executableTarget(
            name: "DockShelf",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/DockShelf",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
