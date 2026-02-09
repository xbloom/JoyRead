import Foundation

/// 远程数据源（网络解析）
class RemoteDataSource {
    
    /// 从URL获取小说信息
    func fetchNovel(fromURL url: String) async throws -> Novel {
        guard let parser = SiteParserFactory.parser(for: url) else {
            throw DataError.unsupportedSite
        }
        
        let completeInfo = try await parser.parseBook(fromURL: url)
        
        return Novel(
            id: completeInfo.bookId,
            title: completeInfo.title,
            author: completeInfo.author,
            coverURL: completeInfo.coverURL,
            introduction: completeInfo.introduction,
            catalogURL: completeInfo.catalogURL,
            chapters: completeInfo.chapters,
            currentChapterURL: completeInfo.chapters.first?.url,
            currentChapterTitle: completeInfo.chapters.first?.title,
            lastReadDate: Date(),
            parserConfig: completeInfo.parserConfig
        )
    }
    
    /// 获取章节内容
    func fetchChapterContent(url: String, config: ParserConfig) async throws -> ChapterContent {
        guard let parser = SiteParserFactory.parser(for: url) else {
            throw DataError.unsupportedSite
        }
        
        return try await parser.parseChapter(
            url: url,
            titleSelector: config.titleSelector,
            contentSelector: config.contentSelector,
            nextChapterSelector: config.nextChapterSelector
        )
    }
}

/// 本地存储
class LocalStorage {
    private let userDefaults = UserDefaults.standard
    private let novelsKey = "saved_novels"
    
    // MARK: - 小说存储
    
    func saveNovel(_ novel: Novel) throws {
        var novels = loadNovels()
        
        // 检查是否已存在
        if let index = novels.firstIndex(where: { $0.id == novel.id }) {
            novels[index] = novel
        } else {
            novels.append(novel)
        }
        
        let data = try JSONEncoder().encode(novels)
        userDefaults.set(data, forKey: novelsKey)
    }
    
    func loadNovels() -> [Novel] {
        guard let data = userDefaults.data(forKey: novelsKey),
              let novels = try? JSONDecoder().decode([Novel].self, from: data) else {
            return []
        }
        return novels.sorted { $0.lastReadDate > $1.lastReadDate }
    }
    
    func updateNovel(_ novel: Novel) throws {
        try saveNovel(novel)
    }
    
    func deleteNovel(_ novel: Novel) throws {
        var novels = loadNovels()
        novels.removeAll { $0.id == novel.id }
        let data = try JSONEncoder().encode(novels)
        userDefaults.set(data, forKey: novelsKey)
    }
    
    // MARK: - 章节缓存
    
    func saveCachedChapter(_ content: ChapterContent, url: String) {
        ChapterCacheManager.shared.cacheChapter(content, url: url)
    }
    
    func loadCachedChapter(url: String) -> ChapterContent? {
        return ChapterCacheManager.shared.getCachedChapter(url: url)
    }
    
    func isChapterCached(url: String) -> Bool {
        return ChapterCacheManager.shared.isCached(url: url)
    }
    
    func clearChapterCache() {
        ChapterCacheManager.shared.clearAllCache()
    }
    
    func getChapterCacheSize() -> Int64 {
        return ChapterCacheManager.shared.getCacheSize()
    }
}

/// 数据错误
enum DataError: LocalizedError {
    case unsupportedSite
    case parseError(String)
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedSite:
            return "不支持的网站"
        case .parseError(let msg):
            return "解析错误: \(msg)"
        case .storageError(let msg):
            return "存储错误: \(msg)"
        }
    }
}
