// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NovelReader",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "NovelReader", targets: ["NovelReader"]),
    ],
    targets: [
        .target(
            name: "NovelReader",
            dependencies: [],
            path: "NovelReader",
            sources: ["HTMLParser.swift", "NovelReaderViewModel.swift"]
        ),
        .testTarget(
            name: "NovelReaderTests",
            dependencies: ["NovelReader"],
            path: "Tests/NovelReaderTests"
        ),
    ]
)
