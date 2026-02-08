import Foundation
import SwiftUI

class NovelReaderViewModel: ObservableObject {
    @Published var chapterTitle: String?
    @Published var chapterContent: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showURLInput: Bool = true
    
    @Published var currentURL: String = "https://www.cuoceng.com/book/95e1a104-af57-421b-aa25-e77bdab6e51c/7a84f4f5-85c3-453e-b18d-f8c7f77be9f0.html"
    @Published var nextChapterURL: String?
    @Published var previousChapterURL: String?
    
    // CSS选择器配置
    @Published var titleSelector: String = "h1"
    @Published var contentSelector: String = "#readcontent"
    @Published var nextChapterSelector: String = "a.next"
    
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
        
        Task {
            do {
                let parser = HTMLParser()
                let result = try await parser.parseNovelPage(
                    url: currentURL,
                    titleSelector: titleSelector,
                    contentSelector: contentSelector,
                    nextChapterSelector: nextChapterSelector
                )
                
                await MainActor.run {
                    self.chapterTitle = result.title
                    self.chapterContent = result.content
                    self.nextChapterURL = result.nextChapterURL
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载失败: \(error.localizedDescription)"
                    self.isLoading = false
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
