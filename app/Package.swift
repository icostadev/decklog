// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OKFPMApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../OKFKit"),
    ],
    targets: [
        .executableTarget(
            name: "OKFPMApp",
            dependencies: [.product(name: "OKFKit", package: "OKFKit")]
        ),
    ]
)
