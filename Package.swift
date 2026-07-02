// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickXia",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "QuickXia", targets: ["QuickXia"])
    ],
    targets: [
        .executableTarget(
            name: "QuickXia",
            path: "Sources/QuickXia"
        )
    ]
)
