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
            sources: [
                // 数据模型
                "Models.swift",
                // 数据层
                "NovelRepository.swift",
                "DataSource.swift",
                // 解析层
                "HTMLParser.swift",
                "SiteParser.swift",
                "SiteConfig.swift",
                "GenericParser.swift",
                "CuocengParser.swift",
                // 工具类
                "ChapterCacheManager.swift",
                "ReadingSettings.swift",
                // ViewModel（待重构）
                "NovelReaderViewModel.swift",
                "BookshelfViewModel.swift"
            ]
        ),
        .testTarget(
            name: "NovelReaderTests",
            dependencies: ["NovelReader"],
            path: "Tests/NovelReaderTests"
        ),
    ]
)
