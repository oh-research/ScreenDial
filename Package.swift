// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenDial",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ScreenDial",
            path: "Sources",
            resources: [
                .copy("../Resources/ScreenDial.icns"),
            ]
        ),
    ]
)
