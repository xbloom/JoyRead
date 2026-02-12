import Foundation
import SwiftUI

class NovelReaderViewModel: ObservableObject {
    @Published var chapterTitle: String?
    @Published var chapterContent: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showURLInput: Bool = false
    
    @Published var currentURL: String = ""
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
    
    private let repository = NovelRepository()
    
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
        
        // 只在没有缓存时显示加载状态
        let isCached = repository.isChapterCached(url: currentURL)
        if !isCached {
            isLoading = true
        }
        errorMessage = nil
        
        Task {
            do {
                // 使用 Repository 获取章节内容（自动处理缓存）
                let config = ParserConfig(
                    titleSelector: titleSelector,
                    contentSelector: contentSelector,
                    nextChapterSelector: nextChapterSelector
                )
                
                let result = try await repository.getChapterContent(url: currentURL, config: config)
                
                await MainActor.run {
                    self.chapterTitle = result.title
                    self.chapterContent = result.content
                    self.nextChapterURL = result.nextChapterURL
                    self.isLoading = false
                    
                    // 预下载后续章节
                    if let nextURL = result.nextChapterURL {
                        preloadNextChapters(startingFrom: nextURL)
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
            
            let config = ParserConfig(
                titleSelector: titleSelector,
                contentSelector: contentSelector,
                nextChapterSelector: nextChapterSelector
            )
            
            while downloadedCount < preloadCount {
                // 如果已缓存，跳过但继续下载下一章
                if repository.isChapterCached(url: currentURL) {
                    // 从缓存读取下一章URL
                    if let cached = try? await repository.getChapterContent(url: currentURL, config: config),
                       let nextURL = cached.nextChapterURL {
                        currentURL = nextURL
                        downloadedCount += 1
                        continue
                    } else {
                        break
                    }
                }
                
                do {
                    let result = try await repository.getChapterContent(url: currentURL, config: config)
                    
                    downloadedCount += 1
                    
                    // 继续下载下一章
                    if let nextURL = result.nextChapterURL {
                        currentURL = nextURL
                    } else {
                        break  // 没有下一章了
                    }
                } catch {
                    print("预下载章节失败: \(error)")
                    break
                }
            }
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
