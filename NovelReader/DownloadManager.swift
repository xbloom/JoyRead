import SwiftUI

class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var errorMessage: String?
    
    private var downloadTask: Task<Void, Never>?
    private let repository = NovelRepository()
    
    /// 下载指定范围的章节
    func downloadChapters(
        chapters: [Chapter],
        config: ParserConfig
    ) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        downloadedCount = 0
        totalCount = chapters.count
        errorMessage = nil
        
        downloadTask = Task {
            for (index, chapter) in chapters.enumerated() {
                // 检查是否已取消
                if Task.isCancelled {
                    break
                }
                
                // 如果已缓存，跳过
                if repository.isChapterCached(url: chapter.url) {
                    await MainActor.run {
                        self.downloadedCount = index + 1
                        self.downloadProgress = Double(index + 1) / Double(totalCount)
                    }
                    continue
                }
                
                do {
                    _ = try await repository.getChapterContent(url: chapter.url, config: config)
                    
                    await MainActor.run {
                        self.downloadedCount = index + 1
                        self.downloadProgress = Double(index + 1) / Double(totalCount)
                    }
                    
                    // 避免请求过快，稍微延迟
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                    
                } catch {
                    await MainActor.run {
                        self.errorMessage = "下载失败: \(error.localizedDescription)"
                    }
                    // 单个章节失败不中断，继续下载
                    print("下载章节失败: \(chapter.title) - \(error)")
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
