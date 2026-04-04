// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "bearcli",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "bearcli",
            path: "Sources/bearcli",
            exclude: ["Info.plist"]
        )
    ]
)
