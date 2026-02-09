import Foundation

/// 完整的书籍信息
struct CompleteBookInfo {
    let bookId: String
    let title: String
    let author: String?
    let coverURL: String?
    let introduction: String?
    let catalogURL: String
    let chapters: [Chapter]
    let parserConfig: ParserConfig
}

/// 网站解析器协议
protocol SiteParser {
    /// 网站域名
    var domain: String { get }
    
    /// 从任意URL获取完整书籍信息（统一流程）
    func parseBook(fromURL url: String) async throws -> CompleteBookInfo
    
    /// 解析章节内容
    func parseChapter(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String) async throws -> ChapterContent
}

/// 网站解析器工厂
class SiteParserFactory {
    static func parser(for url: String) -> SiteParser? {
        // 错层网使用专用解析器（封面提取更准确）
        if url.contains("cuoceng.com") {
            return CuocengParser()
        }
        
        // 其他网站使用通用解析器
        guard let config = SiteConfig.config(for: url) else {
            return nil
        }
        return GenericParser(config: config)
    }
}
