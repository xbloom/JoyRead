import Foundation

/// 通用网站解析器（配置驱动）
class GenericParser: SiteParser {
    private let config: SiteConfig
    
    var domain: String { config.domain }
    
    init(config: SiteConfig) {
        self.config = config
    }
    
    // MARK: - 主入口
    
    func parseBook(fromURL url: String) async throws -> CompleteBookInfo {
        // 1. 提取 bookId
        let bookId = try extractBookId(from: url)
        
        // 2. 获取目录页 HTML
        let catalogURL = config.urlPatterns.catalogURL(bookId)
        let catalogHTML = try await downloadHTML(url: catalogURL)
        
        // 3. 提取基本信息
        let title = extractField(from: catalogHTML, config: config.selectors.title) ?? "未知书名"
        let author = extractField(from: catalogHTML, config: config.selectors.author)
        var coverURL = extractField(from: catalogHTML, config: config.selectors.cover)
        let introduction = config.selectors.intro.flatMap { extractField(from: catalogHTML, config: $0) }
        
        // 4. 修复封面URL：将域名替换为IP（避免Cloudflare拦截）
        if let cover = coverURL {
            coverURL = cover.replacingOccurrences(of: "www.23txtv.com", with: "23.225.143.232")
                           .replacingOccurrences(of: "http://23txtv.com", with: "http://23.225.143.232")
        }
        
        // 5. 提取章节列表（处理分页）
        let chapters = try await extractAllChapters(bookId: bookId, firstPageHTML: catalogHTML)
        
        // 6. 创建 ParserConfig
        let chapterContentConfig = config.selectors.chapterContent
        let parserConfig = ParserConfig(
            titleSelector: chapterContentConfig.titleSelector,
            contentSelector: chapterContentConfig.contentSelector,
            nextChapterSelector: chapterContentConfig.nextChapterSelector
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
    
    func parseChapter(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String) async throws -> ChapterContent {
        var allContent = ""
        var currentURL = url
        var title: String?
        var finalNextChapterURL: String?
        var pageCount = 0
        let maxPages = 10  // 防止无限循环
        
        while pageCount < maxPages {
            let html = try await downloadHTML(url: currentURL)
            
            // 提取标题（只在第一页提取）
            if title == nil {
                title = extractElement(from: html, selector: titleSelector)
            }
            
            // 提取内容
            if let content = extractElement(from: html, selector: contentSelector) {
                if !allContent.isEmpty {
                    allContent += "\n\n"  // 分页之间添加空行
                }
                allContent += content
            }
            
            // 检查是否有下一页（章节内分页）
            if let nextPageURL = extractNextPageURL(from: html, currentURL: currentURL) {
                currentURL = nextPageURL
                pageCount += 1
                continue
            }
            
            // 没有下一页了，提取下一章URL
            finalNextChapterURL = extractNextChapterURL(from: html, selector: nextChapterSelector, baseURL: currentURL)
            break
        }
        
        return ChapterContent(
            title: title,
            content: allContent.isEmpty ? "无法找到内容" : allContent,
            nextChapterURL: finalNextChapterURL
        )
    }
    
    /// 提取章节内的下一页URL（用于分页章节）
    private func extractNextPageURL(from html: String, currentURL: String) -> String? {
        // 零点看书的分页格式：47498308_2.html, 47498308_3.html
        // 查找 "下一页" 链接（明确匹配文本）
        let pattern = "<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>下一页</a>"
        
        if let url = extractMatch(from: html, pattern: pattern, group: 1) {
            var fullURL = url
            
            // 转换相对路径
            if !fullURL.hasPrefix("http") {
                if fullURL.hasPrefix("/") {
                    fullURL = "http://23.225.143.232" + fullURL
                } else if let base = URL(string: currentURL) {
                    fullURL = base.deletingLastPathComponent().appendingPathComponent(fullURL).absoluteString
                }
            }
            
            // 确保不是当前页
            if fullURL != currentURL {
                return fullURL
            }
        }
        
        return nil
    }
    
    /// 提取下一章URL（优先匹配"下一章"文本）
    private func extractNextChapterURL(from html: String, selector: String, baseURL: String) -> String? {
        // 优先查找包含"下一章"文本的链接
        let nextChapterPattern = "<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>下一章</a>"
        if let url = extractMatch(from: html, pattern: nextChapterPattern, group: 1) {
            var fullURL = url
            
            // 转换相对路径
            if !fullURL.hasPrefix("http") {
                if fullURL.hasPrefix("/") {
                    fullURL = "http://23.225.143.232" + fullURL
                } else if let base = URL(string: baseURL) {
                    fullURL = base.deletingLastPathComponent().appendingPathComponent(fullURL).absoluteString
                }
            }
            
            return fullURL
        }
        
        // 如果没找到"下一章"，使用原来的选择器逻辑
        return extractHref(from: html, selector: selector, baseURL: baseURL)
    }
    
    // MARK: - 提取 bookId
    
    private func extractBookId(from url: String) throws -> String {
        for pattern in config.urlPatterns.bookIdPatterns {
            if let bookId = extractMatch(from: url, pattern: pattern, group: 1) {
                return bookId
            }
        }
        throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法从URL提取bookId"])
    }
    
    // MARK: - 提取章节列表（支持分页）
    
    private func extractAllChapters(bookId: String, firstPageHTML: String) async throws -> [Chapter] {
        var allChapters: [Chapter] = []
        
        // 提取第一页章节
        let firstPageChapters = extractChapters(from: firstPageHTML, bookId: bookId)
        allChapters.append(contentsOf: firstPageChapters)
        
        // 如果有分页配置，获取其他页
        if let pagination = config.pagination {
            let pageURLs = extractPaginationURLs(from: firstPageHTML, config: pagination, bookId: bookId)
            
            for pageURL in pageURLs {
                do {
                    let pageHTML = try await downloadHTML(url: pageURL)
                    let pageChapters = extractChapters(from: pageHTML, bookId: bookId)
                    allChapters.append(contentsOf: pageChapters)
                } catch {
                    print("⚠️ 获取分页失败: \(pageURL), 错误: \(error)")
                }
            }
        }
        
        return allChapters
    }
    
    private func extractPaginationURLs(from html: String, config: SiteConfig.PaginationConfig, bookId: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: config.pageSelectPattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        var urls: [String] = []
        let firstPageURL = "http://23.225.143.232/ldks/\(bookId)/"
        
        for match in matches {
            guard let urlRange = Range(match.range(at: 1), in: html) else { continue }
            var url = String(html[urlRange])
            
            // 转换相对路径
            if !url.hasPrefix("http") {
                if url.hasPrefix("/") {
                    url = "http://23.225.143.232" + url
                }
            }
            
            // 跳过第一页（已经获取）
            if url == firstPageURL || url.hasSuffix("/ldks/\(bookId)/") {
                continue
            }
            
            // 避免重复
            if !urls.contains(url) {
                urls.append(url)
            }
            
            // 限制最大页数
            if let maxPages = config.maxPages, urls.count >= maxPages - 1 {
                break
            }
        }
        
        // 按页码数字排序
        return urls.sorted { url1, url2 in
            let num1 = extractPageNumber(from: url1)
            let num2 = extractPageNumber(from: url2)
            return num1 < num2
        }
    }
    
    private func extractPageNumber(from url: String) -> Int {
        // 从 index_N.html 提取数字 N
        if let match = url.range(of: "index_(\\d+)\\.html", options: .regularExpression),
           let numMatch = url[match].range(of: "\\d+", options: .regularExpression) {
            return Int(url[numMatch]) ?? 0
        }
        return 0
    }
    
    // MARK: - 提取章节
    
    private func extractChapters(from html: String, bookId: String) -> [Chapter] {
        let chapterConfig = config.selectors.chapterList
        
        // 如果有容器选择器，提取所有容器内容
        var searchHTML = html
        if let containerPattern = chapterConfig.container {
            // 特殊处理：零点看书有"最新章节"和"正文"两个部分
            // 优先提取"正文"部分
            if containerPattern.contains("正文") {
                // 只提取"正文"部分
                guard let regex = try? NSRegularExpression(pattern: containerPattern, options: [.caseInsensitive]),
                      let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                      let contentRange = Range(match.range(at: 1), in: html) else {
                    return []
                }
                searchHTML = String(html[contentRange])
            } else {
                // 提取所有匹配的容器
                guard let regex = try? NSRegularExpression(pattern: containerPattern, options: [.caseInsensitive]) else {
                    return []
                }
                
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, range: range)
                
                var allContainerContent = ""
                for match in matches {
                    if let contentRange = Range(match.range(at: 1), in: html) {
                        allContainerContent += String(html[contentRange]) + "\n"
                    }
                }
                
                if !allContainerContent.isEmpty {
                    searchHTML = allContainerContent
                }
            }
        }
        
        // 提取章节列表
        guard let regex = try? NSRegularExpression(pattern: chapterConfig.itemPattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(searchHTML.startIndex..., in: searchHTML)
        let matches = regex.matches(in: searchHTML, range: range)
        
        var chapters: [Chapter] = []
        for match in matches {
            guard let urlRange = Range(match.range(at: chapterConfig.urlGroup), in: searchHTML),
                  let titleRange = Range(match.range(at: chapterConfig.titleGroup), in: searchHTML) else {
                continue
            }
            
            var chapterURL = String(searchHTML[urlRange])
            var title = String(searchHTML[titleRange])
            
            // 转换相对路径
            if !chapterURL.hasPrefix("http") {
                if chapterURL.hasPrefix("/") {
                    chapterURL = "http://23.225.143.232" + chapterURL
                }
            }
            
            // 提取 chapterId
            let chapterId = extractChapterId(from: chapterURL) ?? UUID().uuidString
            
            // 清理标题
            title = decodeHTMLEntities(title).trimmingCharacters(in: .whitespacesAndNewlines)
            
            chapters.append(Chapter(id: chapterId, title: title, url: chapterURL))
        }
        
        return chapters
    }
    
    private func extractChapterId(from url: String) -> String? {
        // 尝试从 URL 提取最后的 ID 部分
        if let match = url.range(of: "/([^/]+)\\.html$", options: .regularExpression) {
            let idPart = String(url[match])
            return idPart.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: ".html", with: "")
        }
        return nil
    }
    
    // MARK: - 字段提取
    
    private func extractField(from html: String, config: SiteConfig.SelectorConfig) -> String? {
        // 特殊处理：作者字段可能有多个捕获组
        if config.captureGroup == 0 {
            // 尝试所有捕获组
            guard let regex = try? NSRegularExpression(pattern: config.pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) else {
                return nil
            }
            
            for i in 1..<match.numberOfRanges {
                if let range = Range(match.range(at: i), in: html) {
                    let value = String(html[range])
                    if !value.isEmpty {
                        return cleanupField(value, cleanup: config.cleanup)
                    }
                }
            }
            return nil
        }
        
        // 正常提取
        guard let value = extractMatch(from: html, pattern: config.pattern, group: config.captureGroup) else {
            return nil
        }
        
        return cleanupField(value, cleanup: config.cleanup)
    }
    
    private func cleanupField(_ value: String, cleanup: ((String) -> String)?) -> String {
        var cleaned = value
        
        // 移除 HTML 标签
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // 解码 HTML 实体
        cleaned = decodeHTMLEntities(cleaned)
        
        // 应用自定义清理
        if let cleanup = cleanup {
            cleaned = cleanup(cleaned)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - 章节内容提取（兼容旧接口）
    
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
        guard let content = extractMatch(from: html, pattern: pattern, group: 1) else {
            return nil
        }
        return cleanHTMLContent(content)
    }
    
    private func extractByTag(html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>([\\s\\S]*?)</\(tag)>"
        guard let content = extractMatch(from: html, pattern: pattern, group: 1) else {
            return nil
        }
        return cleanHTMLContent(content)
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
        
        guard var href = extractMatch(from: html, pattern: pattern, group: 1) else {
            return nil
        }
        
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
    
    private func extractMatch(from text: String, pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: group), in: text) else {
            return nil
        }
        return String(text[range])
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
