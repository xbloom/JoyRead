import Foundation
import WebKit

struct NovelChapter {
    let title: String?
    let content: String
    let nextChapterURL: String?
}

class HTMLParser: NSObject {
    func parseNovelPage(url: String, titleSelector: String, contentSelector: String, nextChapterSelector: String) async throws -> NovelChapter {
        guard let pageURL = URL(string: url) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        
        // 下载HTML内容
        let (data, _) = try await URLSession.shared.data(from: pageURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析HTML"])
        }
        
        // 使用JavaScript在WebView中解析
        return try await parseHTMLWithWebView(html: html, baseURL: pageURL, titleSelector: titleSelector, contentSelector: contentSelector, nextChapterSelector: nextChapterSelector)
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
