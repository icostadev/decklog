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
        .testTarget(
            name: "OKFKitTests",
            dependencies: ["OKFKit"]
        ),
    ]
)
