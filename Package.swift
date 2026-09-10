// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Awake",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Awake", targets: ["Awake"])],
    targets: [
        .target(
            name: "AwakeCore",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(name: "Awake", dependencies: ["AwakeCore"]),
        .executableTarget(name: "AwakeChecks", dependencies: ["AwakeCore"], path: "Tests/AwakeCoreTests")
    ]
)
