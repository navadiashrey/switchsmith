// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Switchsmith",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Switchsmith",
            path: "Sources/Switchsmith"
        )
    ]
)
