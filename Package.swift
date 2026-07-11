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
    targets: [
        .executableTarget(
            name: "DockShelf",
            path: "Sources/DockShelf",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "DockShelfTests",
            dependencies: ["DockShelf"],
            path: "Tests/DockShelfTests"
        )
    ]
)
