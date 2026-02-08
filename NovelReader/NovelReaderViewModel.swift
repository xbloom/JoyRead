import Foundation
import SwiftUI

class NovelReaderViewModel: ObservableObject {
    @Published var chapterTitle: String?
    @Published var chapterContent: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showURLInput: Bool = false
    
    @Published var currentURL: String = "https://www.cuoceng.com/book/95e1a104-af57-421b-aa25-e77bdab6e51c/7a84f4f5-85c3-453e-b18d-f8c7f77be9f0.html"
    @Published var nextChapterURL: String?
    @Published var previousChapterURL: String?
    
    // CSS选择器配置
    @Published var titleSelector: String = "h1"
    @Published var contentSelector: String = "#readcontent"
    @Published var nextChapterSelector: String = "a.next"
    
    // 解析模式
    @Published var parseMode: ParseMode = .regex
    
    // 预下载配置
    private let preloadCount = 3  // 预下载后续3章
    
    var hasNextChapter: Bool {
        nextChapterURL != nil
    }
    
    var hasPreviousChapter: Bool {
        previousChapterURL != nil
    }
    
    private var chapterHistory: [String] = []
    
    func loadChapter() {
        guard !currentURL.isEmpty else {
            errorMessage = "请输入有效的URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 先尝试从缓存读取
        if let cached = ChapterCacheManager.shared.getCachedChapter(url: currentURL) {
            self.chapterTitle = cached.title
            self.chapterContent = cached.content
            self.nextChapterURL = cached.nextChapterURL
            self.isLoading = false
            
            // 从缓存读取时也要触发预下载
            if let nextURL = cached.nextChapterURL {
                preloadNextChapters(startingFrom: nextURL)
            }
            return
        }
        
        Task {
            do {
                let parser = HTMLParser()
                let result = try await parser.parseNovelPage(
                    url: currentURL,
                    titleSelector: titleSelector,
                    contentSelector: contentSelector,
                    nextChapterSelector: nextChapterSelector,
                    mode: parseMode
                )
                
                await MainActor.run {
                    self.chapterTitle = result.title
                    self.chapterContent = result.content
                    self.nextChapterURL = result.nextChapterURL
                    self.isLoading = false
                    
                    // 缓存章节
                    ChapterCacheManager.shared.cacheChapter(result, url: currentURL)
                    
                    // 预下载后续章节
                    if let nextURL = result.nextChapterURL {
                        self.preloadNextChapters(startingFrom: nextURL)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 预下载后续多章（后台静默下载）
    private func preloadNextChapters(startingFrom url: String) {
        Task {
            var currentURL = url
            var downloadedCount = 0
            
            while downloadedCount < preloadCount {
                // 如果已缓存，跳过但继续下载下一章
                if ChapterCacheManager.shared.isCached(url: currentURL) {
                    // 从缓存读取下一章URL
                    if let cached = ChapterCacheManager.shared.getCachedChapter(url: currentURL),
                       let nextURL = cached.nextChapterURL {
                        currentURL = nextURL
                        downloadedCount += 1
                        continue
                    } else {
                        break
                    }
                }
                
                do {
                    let parser = HTMLParser()
                    let result = try await parser.parseNovelPage(
                        url: currentURL,
                        titleSelector: titleSelector,
                        contentSelector: contentSelector,
                        nextChapterSelector: nextChapterSelector,
                        mode: parseMode
                    )
                    
                    // 缓存预下载的章节
                    ChapterCacheManager.shared.cacheChapter(result, url: currentURL)
                    
                    downloadedCount += 1
                    
                    // 继续下载下一章
                    if let nextURL = result.nextChapterURL {
                        currentURL = nextURL
                    } else {
                        break  // 没有下一章了
                    }
                    
                    // 避免请求过快
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                    
                } catch {
                    // 预下载失败不影响用户体验，静默处理
                    print("预下载章节失败: \(error)")
                    break
                }
            }
            
            print("✅ 预下载完成: \(downloadedCount) 章")
        }
    }
    
    func loadNextChapter() {
        guard let nextURL = nextChapterURL else { return }
        chapterHistory.append(currentURL)
        previousChapterURL = currentURL
        currentURL = nextURL
        loadChapter()
    }
    
    func loadPreviousChapter() {
        guard let prevURL = previousChapterURL else { return }
        currentURL = prevURL
        if !chapterHistory.isEmpty {
            chapterHistory.removeLast()
            previousChapterURL = chapterHistory.last
        }
        loadChapter()
    }
}
