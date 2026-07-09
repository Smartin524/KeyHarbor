// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyHarbor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KeyHarbor", targets: ["KeyHarbor"])
    ],
    targets: [
        .executableTarget(
            name: "KeyHarbor",
            path: "Sources/KeyHarbor"
        )
    ]
)
