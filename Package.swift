// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "DebugWebSocketClient",
    dependencies: [
	.package(url: "https://github.com/daltoniam/Starscream.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "DebugWebSocketClient",
            dependencies: ["Starscream"]),
    ]
)
