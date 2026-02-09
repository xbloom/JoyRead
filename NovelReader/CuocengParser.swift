import Foundation

/// 错层小说网解析器
class CuocengParser: SiteParser {
    let domain = "cuoceng.com"
    
    // MARK: - 主入口：统一流程
    
    func parseBook(fromURL url: String) async throws -> CompleteBookInfo {
        // 1. 识别URL并提取bookId
        let bookId = try extractBookIdFromAnyURL(url: url)
        
        // 2. 构建标准URL
        let bookDetailURL = "https://www.\(domain)/book/\(bookId).html"
        let catalogURL = "https://www.\(domain)/book/chapter/\(bookId).html"
        
        // 3. 从书籍详情页获取完整信息（书名、作者、封面、简介）
        let detailHTML = try await downloadHTML(url: bookDetailURL)
        let title = extractTitle(from: detailHTML) ?? "未知书名"
        let author = extractAuthor(from: detailHTML)
        let coverURL = extractCover(from: detailHTML)
        let introduction = extractIntroduction(from: detailHTML)
        
        // 4. 从目录页获取章节列表
        let catalogHTML = try await downloadHTML(url: catalogURL)
        let chapters = try extractChapters(from: catalogHTML, bookId: bookId)
        
        // 5. 创建 ParserConfig
        let parserConfig = ParserConfig(
            titleSelector: "h1",
            contentSelector: "#readcontent",
            nextChapterSelector: "a.next"
        )
        
        return CompleteBookInfo(
            bookId: bookId,
            title: title,
            author: author,
            coverURL: coverURL,
            introduction: introduction,
            catalogURL: catalogURL,
            chapters: chapters,
            parserConfig: parserConfig
        )
    }
    
    // MARK: - 提取bookId（支持所有URL类型）
    
    private func extractBookIdFromAnyURL(url: String) throws -> String {
        // 尝试各种URL格式
        let patterns = [
            "/book/([a-f0-9-]+)/[a-f0-9-]+\\.html",  // 章节页
            "/book/chapter/([a-f0-9-]+)\\.html",      // 目录页
            "/book/([a-f0-9-]+)\\.html"               // 书籍详情页
        ]
        
        for pattern in patterns {
            if let bookId = extractBookId(from: url, pattern: pattern) {
                return bookId
            }
        }
        
        throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法从URL提取bookId"])
    }
    
    // MARK: - 解析章节内容
    
    func parseChapter(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String) async throws -> ChapterContent {
        let html = try await downloadHTML(url: url)
        return try parseChapterContent(html: html, baseURL: url, titleSelector: titleSelector, contentSelector: contentSelector, nextChapterSelector: nextChapterSelector)
    }
    
    // MARK: - 工具方法
    
    private func downloadHTML(url: String) async throws -> String {
        guard let pageURL = URL(string: url) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: pageURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析HTML"])
        }
        
        return html
    }
    
    private func extractBookId(from url: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
              let range = Range(match.range(at: 1), in: url) else {
            return nil
        }
        return String(url[range])
    }
    
    // MARK: - HTML内容提取
    
    private func extractTitle(from html: String) -> String? {
        // 优先从书籍详情页提取：<h1>书名</h1>
        let detailPattern = "<h1>([^<]+)</h1>"
        if let regex = try? NSRegularExpression(pattern: detailPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            var title = String(html[range])
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            // 移除 " 目录" 后缀（如果是目录页）
            title = title.replacingOccurrences(of: "\\s*目录\\s*$", with: "", options: .regularExpression)
            if !title.isEmpty {
                return title
            }
        }
        
        return nil
    }
    
    private func extractAuthor(from html: String) -> String? {
        // 1. 从目录页提取：作者：<a href="...">作者名</a>
        let catalogPattern = "作者：<a[^>]*>([^<]+)</a>"
        if let regex = try? NSRegularExpression(pattern: catalogPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            var author = String(html[range])
            author = author.trimmingCharacters(in: .whitespacesAndNewlines)
            if !author.isEmpty {
                return author
            }
        }
        
        // 2. 从书籍详情页提取：<a class="author">作者名 著</a>
        let detailPattern = "<a[^>]*class=[\"']author[\"'][^>]*>([^<]+)</a>"
        if let regex = try? NSRegularExpression(pattern: detailPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            var author = String(html[range])
            // 移除 " 著" 后缀
            author = author.replacingOccurrences(of: "\\s*著\\s*$", with: "", options: .regularExpression)
            author = decodeHTMLEntities(author)
            author = author.trimmingCharacters(in: .whitespacesAndNewlines)
            if !author.isEmpty {
                return author
            }
        }
        
        return nil
    }
    
    private func extractCover(from html: String) -> String? {
        // 1. 从章节页面的隐藏input提取
        let inputPattern = "<input[^>]*id=[\"']bookCover[\"'][^>]*value=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: inputPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let coverURL = String(html[range])
            if !coverURL.isEmpty {
                return coverURL
            }
        }
        
        // 2. 从书籍详情页的img标签提取（data-src属性）
        let imgPattern = "<img[^>]*class=[\"'][^\"']*cover[^\"']*[\"'][^>]*data-src=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: imgPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let coverURL = String(html[range])
            if !coverURL.isEmpty {
                return coverURL
            }
        }
        
        // 3. 从书籍详情页的img标签提取（src属性）
        let imgSrcPattern = "<img[^>]*class=[\"'][^\"']*cover[^\"']*[\"'][^>]*src=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: imgSrcPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let coverURL = String(html[range])
            // 跳过默认图片
            if !coverURL.contains("default.gif") && !coverURL.isEmpty {
                return coverURL
            }
        }
        
        return nil
    }
    
    private func extractIntroduction(from html: String) -> String? {
        // 从书籍详情页提取简介（如果有）
        let pattern = "<div[^>]*class=[\"'][^\"']*intro[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var intro = String(html[range])
        intro = intro.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        intro = intro.trimmingCharacters(in: .whitespacesAndNewlines)
        return intro.isEmpty ? nil : intro
    }
    
    private func extractChapters(from html: String, bookId: String) throws -> [Chapter] {
        // 匹配格式: <a href="/book/{bookId}/{chapterId}.html"><span>章节标题</span></a>
        let pattern = "<a href=\"/book/\(bookId)/([a-f0-9-]+)\\.html\">\\s*<span[^>]*>([^<]+)</span>\\s*</a>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            throw NSError(domain: "RegexError", code: -1, userInfo: [NSLocalizedDescriptionKey: "正则表达式创建失败"])
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        var chapters: [Chapter] = []
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let chapterIdRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html) else {
                continue
            }
            
            let chapterId = String(html[chapterIdRange])
            var title = String(html[titleRange])
            
            // 清理HTML实体
            title = decodeHTMLEntities(title)
            
            let chapterURL = "https://www.\(domain)/book/\(bookId)/\(chapterId).html"
            chapters.append(Chapter(id: chapterId, title: title, url: chapterURL))
        }
        
        return chapters
    }
    
    private func parseChapterContent(html: String, baseURL: String, titleSelector: String, contentSelector: String, nextChapterSelector: String) throws -> ChapterContent {
        let title = extractElement(from: html, selector: titleSelector)
        let content = extractElement(from: html, selector: contentSelector) ?? "无法找到内容"
        let nextURL = extractHref(from: html, selector: nextChapterSelector, baseURL: baseURL)
        
        return ChapterContent(title: title, content: content, nextChapterURL: nextURL)
    }
    
    private func extractElement(from html: String, selector: String) -> String? {
        if selector.hasPrefix("#") {
            let id = String(selector.dropFirst())
            return extractById(html: html, id: id)
        } else if selector.hasPrefix(".") {
            let className = String(selector.dropFirst())
            return extractByClass(html: html, className: className)
        } else {
            return extractByTag(html: html, tag: selector)
        }
    }
    
    private func extractById(html: String, id: String) -> String? {
        // 特殊处理：readcontent -> showReading
        let actualId = (id == "readcontent") ? "showReading" : id
        
        guard let idRange = html.range(of: "id=\"\(actualId)\"", options: .caseInsensitive) else {
            return nil
        }
        
        let beforeId = html[..<idRange.lowerBound]
        guard let tagStart = beforeId.lastIndex(of: "<") else {
            return nil
        }
        
        let afterTagStart = html[html.index(after: tagStart)...]
        guard let spaceOrBracket = afterTagStart.firstIndex(where: { $0 == " " || $0 == ">" }) else {
            return nil
        }
        let tagName = String(afterTagStart[..<spaceOrBracket])
        
        guard let contentStart = html[idRange.upperBound...].firstIndex(of: ">") else {
            return nil
        }
        let contentStartIndex = html.index(after: contentStart)
        
        let endTag = "</\(tagName)>"
        guard let endRange = html[contentStartIndex...].range(of: endTag, options: .caseInsensitive) else {
            return nil
        }
        
        var content = String(html[contentStartIndex..<endRange.lowerBound])
        content = cleanHTMLContent(content)
        return content.isEmpty ? nil : content
    }
    
    private func extractByClass(html: String, className: String) -> String? {
        let pattern = "<[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var content = String(html[range])
        content = cleanHTMLContent(content)
        return content.isEmpty ? nil : content
    }
    
    private func extractByTag(html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>([\\s\\S]*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var content = String(html[range])
        content = cleanHTMLContent(content)
        return content.isEmpty ? nil : content
    }
    
    private func extractHref(from html: String, selector: String, baseURL: String) -> String? {
        var pattern = ""
        
        if selector.contains(".") {
            let parts = selector.split(separator: ".")
            if parts.count == 2 {
                let tag = parts[0]
                let className = parts[1]
                pattern = "<\(tag)[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*href=[\"']([^\"']+)[\"']"
            }
        } else {
            pattern = "<\(selector)[^>]*href=[\"']([^\"']+)[\"']"
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var href = String(html[range])
        
        // 处理相对URL
        if !href.hasPrefix("http") {
            if href.hasPrefix("/") {
                href = "https://www.\(domain)" + href
            } else if let base = URL(string: baseURL) {
                href = base.deletingLastPathComponent().appendingPathComponent(href).absoluteString
            }
        }
        
        return href
    }
    
    private func cleanHTMLContent(_ content: String) -> String {
        var cleaned = content
        
        // 移除script和style标签
        cleaned = cleaned.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // 转换换行标签
        cleaned = cleaned.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "<p[^>]*>", with: "", options: .regularExpression)
        
        // 移除所有HTML标签
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // 解码HTML实体
        cleaned = decodeHTMLEntities(cleaned)
        
        // 清理多余空白
        let lines = cleaned.components(separatedBy: .newlines)
        let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        cleaned = cleanedLines.joined(separator: "\n")
        
        return cleaned
    }
    
    private func decodeHTMLEntities(_ text: String) -> String {
        var decoded = text
        decoded = decoded.replacingOccurrences(of: "&nbsp;", with: " ")
        decoded = decoded.replacingOccurrences(of: "&lt;", with: "<")
        decoded = decoded.replacingOccurrences(of: "&gt;", with: ">")
        decoded = decoded.replacingOccurrences(of: "&amp;", with: "&")
        decoded = decoded.replacingOccurrences(of: "&quot;", with: "\"")
        decoded = decoded.replacingOccurrences(of: "&#39;", with: "'")
        return decoded
    }
}
