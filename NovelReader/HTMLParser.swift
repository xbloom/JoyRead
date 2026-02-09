import Foundation
import WebKit

enum ParseMode {
    case webView
    case regex
}

/// HTML解析器（统一入口）
class HTMLParser: NSObject {
    
    /// 从任意URL添加书籍
    func parseBook(fromURL url: String) async throws -> (Novel, [Chapter]) {
        guard let parser = SiteParserFactory.parser(for: url) else {
            throw DataError.unsupportedSite
        }
        
        let completeInfo = try await parser.parseBook(fromURL: url)
        
        let novel = Novel(
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
            parserConfig: .default
        )
        
        return (novel, completeInfo.chapters)
    }
    
    /// 解析章节内容
    func parseNovelPage(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String, mode: ParseMode = .regex) async throws -> ChapterContent {
        guard let parser = SiteParserFactory.parser(for: url) else {
            throw DataError.unsupportedSite
        }
        
        return try await parser.parseChapter(url: url, titleSelector: titleSelector, contentSelector: contentSelector, nextChapterSelector: nextChapterSelector)
    }
}
