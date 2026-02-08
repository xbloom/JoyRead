import Foundation

struct CachedChapter: Codable {
    let url: String
    let title: String?
    let content: String
    let nextChapterURL: String?
    let cachedDate: Date
}

class ChapterCacheManager {
    static let shared = ChapterCacheManager()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("ChapterCache", isDirectory: true)
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - 缓存操作
    
    /// 保存章节到缓存
    func cacheChapter(_ chapter: NovelChapter, url: String) {
        let cached = CachedChapter(
            url: url,
            title: chapter.title,
            content: chapter.content,
            nextChapterURL: chapter.nextChapterURL,
            cachedDate: Date()
        )
        
        let fileURL = cacheFileURL(for: url)
        
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: fileURL)
        } catch {
            print("缓存章节失败: \(error)")
        }
    }
    
    /// 从缓存读取章节
    func getCachedChapter(url: String) -> NovelChapter? {
        let fileURL = cacheFileURL(for: url)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let cached = try JSONDecoder().decode(CachedChapter.self, from: data)
            
            return NovelChapter(
                title: cached.title,
                content: cached.content,
                nextChapterURL: cached.nextChapterURL
            )
        } catch {
            print("读取缓存失败: \(error)")
            return nil
        }
    }
    
    /// 检查章节是否已缓存
    func isCached(url: String) -> Bool {
        let fileURL = cacheFileURL(for: url)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 删除指定章节缓存
    func removeCache(url: String) {
        let fileURL = cacheFileURL(for: url)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// 清空所有缓存
    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// 获取缓存大小（字节）
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    /// 获取缓存章节数量
    func getCachedChapterCount() -> Int {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return files.count
    }
    
    // MARK: - 私有方法
    
    private func cacheFileURL(for url: String) -> URL {
        // 使用URL的MD5作为文件名
        let filename = url.md5 + ".json"
        return cacheDirectory.appendingPathComponent(filename)
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5: String {
        guard let data = self.data(using: .utf8) else { return self }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
