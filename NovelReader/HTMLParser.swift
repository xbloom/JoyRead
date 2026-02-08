import Foundation
import WebKit

struct NovelChapter {
    let title: String?
    let content: String
    let nextChapterURL: String?
}

enum ParseMode {
    case webView
    case regex
}

class HTMLParser: NSObject {
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
