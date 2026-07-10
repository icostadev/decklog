// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OKFKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "OKFKit", targets: ["OKFKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "OKFKit",
            dependencies: ["Yams"]
        ),
        // A dependency-light smoke check runnable with only the Command Line Tools
        // (no XCTest / full Xcode). Mirrors the key OKFKit tests. See scripts/smoke.sh.
        .executableTarget(
            name: "OKFKitSmoke",
            dependencies: ["OKFKit"]
        ),
        .testTarget(
            name: "OKFKitTests",
            dependencies: ["OKFKit"]
        ),
    ]
)
