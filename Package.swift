// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "bear-cli",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "bear-cli",
            path: "Sources/BearCLI"
        )
    ]
)
