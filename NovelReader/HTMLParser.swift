import Foundation
import WebKit

struct NovelChapter {
    let title: String?
    let content: String
    let nextChapterURL: String?
}

struct ChapterListItem: Identifiable {
    let id: String  // chapterId
    let title: String
    let url: String
}

struct BookInfo {
    let bookId: String
    let title: String
    let author: String?
    let coverURL: String?
    let catalogURL: String
}

enum ParseMode {
    case webView
    case regex
}

class HTMLParser: NSObject {
    /// 解析目录页面，获取书籍信息和章节列表
    /// - Parameter catalogURL: 目录页面URL，格式如 https://www.cuoceng.com/book/chapter/{bookId}.html
    /// - Returns: (书籍信息, 章节列表)
    func parseCatalog(url catalogURL: String) async throws -> (bookInfo: BookInfo, chapters: [ChapterListItem]) {
        guard let url = URL(string: catalogURL) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的目录URL"])
        }
        
        // 下载HTML内容
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析HTML"])
        }
        
        // 提取bookId
        guard let bookId = extractBookId(from: catalogURL) else {
            throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法提取bookId"])
        }
        
        // 提取书名
        let bookTitle = extractBookTitle(from: html) ?? "未知书名"
        
        // 提取作者
        let author = extractAuthor(from: html)
        
        // 提取封面URL（如果有）
        let coverURL = extractCoverURL(from: html)
        
        // 创建书籍信息
        let bookInfo = BookInfo(
            bookId: bookId,
            title: bookTitle,
            author: author,
            coverURL: coverURL,
            catalogURL: catalogURL
        )
        
        // 提取章节列表
        let chapters = try extractChapters(from: html, bookId: bookId)
        
        return (bookInfo, chapters)
    }
    
    /// 提取书名
    private func extractBookTitle(from html: String) -> String? {
        // 从 <h1>木叶手记 目录</h1> 提取
        let pattern = "<h1>([^<]+)\\s*目录</h1>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var title = String(html[range])
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }
    
    /// 提取作者
    private func extractAuthor(from html: String) -> String? {
        // 从 <span>作者：<a href="...">短腿跑得慢</a></span> 提取
        let pattern = "作者：<a[^>]*>([^<]+)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        var author = String(html[range])
        author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return author.isEmpty ? nil : author
    }
    
    /// 提取封面URL
    private func extractCoverURL(from html: String) -> String? {
        // 尝试从多个可能的位置提取封面
        // 1. 查找 class="bookCover" 附近的 img 标签
        let patterns = [
            "<img[^>]*src=[\"']([^\"']*book[^\"']*)[\"']",
            "<img[^>]*src=[\"']([^\"']*cover[^\"']*)[\"']",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                var coverURL = String(html[range])
                
                // 处理相对URL
                if !coverURL.hasPrefix("http") {
                    if coverURL.hasPrefix("//") {
                        coverURL = "https:" + coverURL
                    } else if coverURL.hasPrefix("/") {
                        coverURL = "https://www.cuoceng.com" + coverURL
                    }
                }
                
                return coverURL
            }
        }
        
        return nil
    }
    
    /// 提取章节列表
    private func extractChapters(from html: String, bookId: String) throws -> [ChapterListItem] {
        // 使用正则表达式提取章节列表
        // 匹配格式: <a href="/book/{bookId}/{chapterId}.html">章节标题</a>
        let pattern = "<a href=\"/book/\(bookId)/([a-f0-9-]+)\\.html\">\\s*<span[^>]*>([^<]+)</span>\\s*</a>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            throw NSError(domain: "RegexError", code: -1, userInfo: [NSLocalizedDescriptionKey: "正则表达式创建失败"])
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        var chapters: [ChapterListItem] = []
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let chapterIdRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html) else {
                continue
            }
            
            let chapterId = String(html[chapterIdRange])
            var title = String(html[titleRange])
            
            // 清理标题中的HTML实体
            title = title.replacingOccurrences(of: "&nbsp;", with: " ")
            title = title.replacingOccurrences(of: "&lt;", with: "<")
            title = title.replacingOccurrences(of: "&gt;", with: ">")
            title = title.replacingOccurrences(of: "&amp;", with: "&")
            title = title.replacingOccurrences(of: "&quot;", with: "\"")
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let chapterURL = "https://www.cuoceng.com/book/\(bookId)/\(chapterId).html"
            
            chapters.append(ChapterListItem(id: chapterId, title: title, url: chapterURL))
        }
        
        return chapters
    }
    
    /// 从URL中提取bookId
    private func extractBookId(from urlString: String) -> String? {
        // 从 https://www.cuoceng.com/book/chapter/{bookId}.html 提取 bookId
        let pattern = "/book/chapter/([a-f0-9-]+)\\.html"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
              let range = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        return String(urlString[range])
    }
    
    func parseNovelPage(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String, mode: ParseMode = .regex) async throws -> NovelChapter {
        guard let pageURL = URL(string: url) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        
        // 下载HTML内容
        let (data, _) = try await URLSession.shared.data(from: pageURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析HTML"])
        }
        
        switch mode {
        case .webView:
            return try await parseHTMLWithWebView(html: html, baseURL: pageURL, titleSelector: titleSelector, contentSelector: contentSelector, nextChapterSelector: nextChapterSelector)
        case .regex:
            return try parseHTMLWithRegex(html: html, baseURL: pageURL, titleSelector: titleSelector, contentSelector: contentSelector, nextChapterSelector: nextChapterSelector)
        }
    }
    
    private func parseHTMLWithRegex(html: String, baseURL: URL, titleSelector: String, contentSelector: String, nextChapterSelector: String) throws -> NovelChapter {
        // 简单的CSS选择器解析（支持基本的标签、id、class选择器）
        func extractContent(from html: String, selector: String) -> String? {
            var pattern = ""
            
            if selector.hasPrefix("#") {
                // ID选择器: #readcontent
                let id = String(selector.dropFirst())
                
                // 特殊处理：如果是 #readcontent，直接查找 id="showReading" 的内容
                if id == "readcontent" {
                    // 查找 id="showReading" 的内容
                    guard let showReadingRange = html.range(of: "id=\"showReading\"", options: .caseInsensitive) else {
                        // 如果没有 showReading，就用原来的逻辑
                        return extractById(html: html, id: id)
                    }
                    return extractById(html: html, id: "showReading")
                }
                
                return extractById(html: html, id: id)
                
            } else if selector.hasPrefix(".") {
                // Class选择器: .content
                let className = String(selector.dropFirst())
                pattern = "<[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</[^>]*>"
            } else {
                // 标签选择器: h1
                pattern = "<\(selector)[^>]*>([\\s\\S]*?)</\(selector)>"
            }
            
            guard !pattern.isEmpty else { return nil }
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return nil
            }
            
            let range = NSRange(html.startIndex..., in: html)
            guard let match = regex.firstMatch(in: html, range: range),
                  let contentRange = Range(match.range(at: 1), in: html) else {
                return nil
            }
            
            var content = String(html[contentRange])
            
            // 移除HTML标签
            content = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            // 解码HTML实体
            content = content.replacingOccurrences(of: "&nbsp;", with: " ")
            content = content.replacingOccurrences(of: "&lt;", with: "<")
            content = content.replacingOccurrences(of: "&gt;", with: ">")
            content = content.replacingOccurrences(of: "&amp;", with: "&")
            content = content.replacingOccurrences(of: "&quot;", with: "\"")
            content = content.replacingOccurrences(of: "&#39;", with: "'")
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return content.isEmpty ? nil : content
        }
        
        func extractById(html: String, id: String) -> String? {
            guard let idRange = html.range(of: "id=\"\(id)\"", options: .caseInsensitive) else {
                return nil
            }
            
            // 从 id 位置往前找到标签名
            let beforeId = html[..<idRange.lowerBound]
            guard let tagStart = beforeId.lastIndex(of: "<") else {
                return nil
            }
            
            // 提取标签名
            let afterTagStart = html[html.index(after: tagStart)...]
            guard let spaceOrBracket = afterTagStart.firstIndex(where: { $0 == " " || $0 == ">" }) else {
                return nil
            }
            let tagName = String(afterTagStart[..<spaceOrBracket])
            
            // 找到这个标签的结束位置
            guard let contentStart = html[idRange.upperBound...].firstIndex(of: ">") else {
                return nil
            }
            let contentStartIndex = html.index(after: contentStart)
            
            // 查找结束标签
            let endTag = "</\(tagName)>"
            guard let endRange = html[contentStartIndex...].range(of: endTag, options: .caseInsensitive) else {
                return nil
            }
            
            var content = String(html[contentStartIndex..<endRange.lowerBound])
            
            // 移除script和style标签及其内容
            content = content.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
            content = content.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
            
            // 将<br>和<p>标签转换为换行
            content = content.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
            content = content.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
            content = content.replacingOccurrences(of: "<p[^>]*>", with: "", options: .regularExpression)
            
            // 移除所有HTML标签
            content = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            
            // 解码HTML实体
            content = content.replacingOccurrences(of: "&nbsp;", with: " ")
            content = content.replacingOccurrences(of: "&lt;", with: "<")
            content = content.replacingOccurrences(of: "&gt;", with: ">")
            content = content.replacingOccurrences(of: "&amp;", with: "&")
            content = content.replacingOccurrences(of: "&quot;", with: "\"")
            content = content.replacingOccurrences(of: "&#39;", with: "'")
            
            // 清理多余空白，但保留段落换行
            let lines = content.components(separatedBy: .newlines)
            let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            content = cleanedLines.joined(separator: "\n")
            
            return content.isEmpty ? nil : content
        }
        
        func extractHref(from html: String, selector: String) -> String? {
            // 提取链接: a.next
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
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            
            let range = NSRange(html.startIndex..., in: html)
            guard let match = regex.firstMatch(in: html, range: range),
                  let hrefRange = Range(match.range(at: 1), in: html) else {
                return nil
            }
            
            var href = String(html[hrefRange])
            
            // 处理相对URL
            if !href.hasPrefix("http") {
                if href.hasPrefix("/") {
                    href = baseURL.scheme! + "://" + baseURL.host! + href
                } else {
                    href = baseURL.deletingLastPathComponent().appendingPathComponent(href).absoluteString
                }
            }
            
            return href
        }
        
        let title = extractContent(from: html, selector: titleSelector)
        let content = extractContent(from: html, selector: contentSelector) ?? "无法找到内容"
        let nextURL = extractHref(from: html, selector: nextChapterSelector)
        
        return NovelChapter(title: title, content: content, nextChapterURL: nextURL)
    }
    
    private func parseHTMLWithWebView(html: String, baseURL: URL, titleSelector: String, contentSelector: String, nextChapterSelector: String) async throws -> NovelChapter {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let config = WKWebViewConfiguration()
                let webView = WKWebView(frame: .zero, configuration: config)
                
                let delegate = NavigationDelegate { success in
                    if !success {
                        continuation.resume(throwing: NSError(domain: "LoadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "页面加载失败"]))
                        return
                    }
                    
                    let script = """
                    (function() {
                        try {
                            var titleElement = document.querySelector('\(titleSelector)');
                            var contentElement = document.querySelector('\(contentSelector)');
                            var nextElement = document.querySelector('\(nextChapterSelector)');
                            
                            var result = {
                                title: titleElement ? titleElement.innerText : '',
                                content: contentElement ? contentElement.innerText : '无法找到内容',
                                nextURL: nextElement ? nextElement.href : ''
                            };
                            
                            return JSON.stringify(result);
                        } catch(e) {
                            return JSON.stringify({ error: e.toString() });
                        }
                    })();
                    """
                    
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let jsonString = result as? String else {
                            continuation.resume(throwing: NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "JS返回类型错误: \\(type(of: result))"]))
                            return
                        }
                        
                        guard let jsonData = jsonString.data(using: .utf8),
                              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                            continuation.resume(throwing: NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON解析失败: \\(jsonString)"]))
                            return
                        }
                        
                        if let errorMsg = dict["error"] as? String {
                            continuation.resume(throwing: NSError(domain: "JavaScriptError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg]))
                            return
                        }
                        
                        let chapter = NovelChapter(
                            title: (dict["title"] as? String)?.isEmpty == false ? dict["title"] as? String : nil,
                            content: dict["content"] as? String ?? "无内容",
                            nextChapterURL: (dict["nextURL"] as? String)?.isEmpty == false ? dict["nextURL"] as? String : nil
                        )
                        
                        continuation.resume(returning: chapter)
                    }
                }
                
                webView.navigationDelegate = delegate
                webView.loadHTMLString(html, baseURL: baseURL)
                
                // 保持delegate引用
                objc_setAssociatedObject(webView, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
}

private class NavigationDelegate: NSObject, WKNavigationDelegate {
    let completion: (Bool) -> Void
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 等待一小段时间确保DOM完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.completion(true)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completion(false)
    }
}
