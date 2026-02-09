import SwiftUI

class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var errorMessage: String?
    
    private var downloadTask: Task<Void, Never>?
    
    /// 下载指定范围的章节
    func downloadChapters(
        chapters: [Chapter],
        titleSelector: String,
        contentSelector: String,
        nextChapterSelector: String,
        parseMode: ParseMode = .regex
    ) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        downloadedCount = 0
        totalCount = chapters.count
        errorMessage = nil
        
        downloadTask = Task {
            let parser = HTMLParser()
            
            for (index, chapter) in chapters.enumerated() {
                // 检查是否已取消
                if Task.isCancelled {
                    break
                }
                
                // 如果已缓存，跳过
                if ChapterCacheManager.shared.isCached(url: chapter.url) {
                    await MainActor.run {
                        self.downloadedCount = index + 1
                        self.downloadProgress = Double(index + 1) / Double(totalCount)
                    }
                    continue
                }
                
                do {
                    let result = try await parser.parseNovelPage(
                        url: chapter.url,
                        titleSelector: titleSelector,
                        contentSelector: contentSelector,
                        nextChapterSelector: nextChapterSelector,
                        mode: parseMode
                    )
                    
                    // 缓存章节
                    ChapterCacheManager.shared.cacheChapter(result, url: chapter.url)
                    
                    await MainActor.run {
                        self.downloadedCount = index + 1
                        self.downloadProgress = Double(index + 1) / Double(totalCount)
                    }
                    
                    // 避免请求过快，稍微延迟
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                    
                } catch {
                    await MainActor.run {
                        self.errorMessage = "下载失败: \(error.localizedDescription)"
                    }
                    break
                }
            }
            
            await MainActor.run {
                self.isDownloading = false
            }
        }
    }
    
    /// 取消下载
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
    }
}
