import Foundation

/// 小说数据仓储（数据访问层）
class NovelRepository {
    private let remoteDataSource: RemoteDataSource
    private let localStorage: LocalStorage
    
    init(remoteDataSource: RemoteDataSource = RemoteDataSource(),
         localStorage: LocalStorage = LocalStorage()) {
        self.remoteDataSource = remoteDataSource
        self.localStorage = localStorage
    }
    
    // MARK: - 小说管理
    
    /// 从URL添加小说
    func addNovel(fromURL url: String, config: ParserConfig = .default) async throws -> Novel {
        // 1. 从网络获取小说信息
        let novel = try await remoteDataSource.fetchNovel(fromURL: url, config: config)
        
        // 2. 保存到本地
        try localStorage.saveNovel(novel)
        
        return novel
    }
    
    /// 获取所有小说
    func getAllNovels() -> [Novel] {
        return localStorage.loadNovels()
    }
    
    /// 更新小说
    func updateNovel(_ novel: Novel) throws {
        try localStorage.updateNovel(novel)
    }
    
    /// 删除小说
    func deleteNovel(_ novel: Novel) throws {
        try localStorage.deleteNovel(novel)
    }
    
    // MARK: - 章节管理
    
    /// 获取章节内容（优先从缓存）
    func getChapterContent(url: String, config: ParserConfig) async throws -> ChapterContent {
        // 1. 检查缓存
        if let cached = localStorage.loadCachedChapter(url: url) {
            return cached
        }
        
        // 2. 从网络获取
        let content = try await remoteDataSource.fetchChapterContent(
            url: url,
            config: config
        )
        
        // 3. 保存到缓存
        localStorage.saveCachedChapter(content, url: url)
        
        return content
    }
    
    /// 检查章节是否已缓存
    func isChapterCached(url: String) -> Bool {
        return localStorage.isChapterCached(url: url)
    }
    
    /// 批量下载章节
    func downloadChapters(_ chapters: [Chapter], config: ParserConfig, 
                         onProgress: @escaping (Int, Int) -> Void) async throws {
        for (index, chapter) in chapters.enumerated() {
            // 跳过已缓存的章节
            if isChapterCached(url: chapter.url) {
                onProgress(index + 1, chapters.count)
                continue
            }
            
            do {
                let content = try await remoteDataSource.fetchChapterContent(
                    url: chapter.url,
                    config: config
                )
                localStorage.saveCachedChapter(content, url: chapter.url)
                onProgress(index + 1, chapters.count)
                
                // 避免请求过快
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            } catch {
                // 单个章节失败不影响整体
                print("下载章节失败: \(chapter.title) - \(error)")
            }
        }
    }
    
    /// 清空章节缓存
    func clearChapterCache() {
        localStorage.clearChapterCache()
    }
    
    /// 获取缓存大小
    func getCacheSize() -> Int64 {
        return localStorage.getChapterCacheSize()
    }
}
