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
        if url.contains("cuoceng.com") {
            return CuocengParser()
        }
        // 后续添加其他网站
        return nil
    }
}
