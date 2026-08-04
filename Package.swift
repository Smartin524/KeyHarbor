// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "keyharbor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "keyharbor", targets: ["keyharbor"])
    ],
    targets: [
        .executableTarget(
            name: "keyharbor",
            path: "Sources/keyharbor"
        )
    ]
)
