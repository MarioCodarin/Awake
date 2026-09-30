// swift-tools-version: 5.9
import PackageDescription

// Dependency rule: AwakeCore imports no system frameworks beyond Foundation/Combine.
// Everything that touches IOKit, ServiceManagement, Process or UserDefaults lives in AwakePlatform.
let package = Package(
    name: "Awake",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Awake", targets: ["Awake"])],
    targets: [
        // Pure logic: models, service protocols, SleepModel.
        .target(name: "AwakeCore"),
        // Real system integrations behind the AwakeCore protocols.
        .target(
            name: "AwakePlatform",
            dependencies: ["AwakeCore"],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        // In-memory fakes and controllable clocks for tests and previews.
        .target(name: "AwakeTestSupport", dependencies: ["AwakeCore"]),
        // SwiftUI popover and its components.
        .target(name: "AwakeUI", dependencies: ["AwakeCore"]),
        // App entry point and composition root.
        .executableTarget(name: "Awake", dependencies: ["AwakeCore", "AwakePlatform", "AwakeUI"]),
        // Executable check suite (`swift run AwakeChecks`); works without XCTest.
        .executableTarget(
            name: "AwakeChecks",
            dependencies: ["AwakeCore", "AwakePlatform", "AwakeTestSupport"],
            path: "Tests/AwakeCoreTests"
        )
    ]
)
