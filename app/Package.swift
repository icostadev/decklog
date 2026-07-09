// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Decklog",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../OKFKit"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Decklog",
            dependencies: [
                .product(name: "OKFKit", package: "OKFKit"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]
        ),
    ]
)
