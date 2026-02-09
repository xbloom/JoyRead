import Foundation

// MARK: - 网站配置

/// 网站配置（配置驱动的解析器）
struct SiteConfig {
    let domain: String
    let name: String
    let urlPatterns: URLPatterns
    let selectors: Selectors
    let pagination: PaginationConfig?
    
    /// URL 模式配置
    struct URLPatterns {
        /// bookId 提取正则（按优先级）
        let bookIdPatterns: [String]
        /// 构建目录页 URL
        let catalogURL: (String) -> String
        /// 构建章节页 URL（可选，用于相对路径转换）
        let chapterURL: ((String, String) -> String)?
    }
    
    /// HTML 选择器配置
    struct Selectors {
        let title: SelectorConfig
        let author: SelectorConfig
        let cover: SelectorConfig
        let intro: SelectorConfig?
        let chapterList: ChapterListConfig
        let chapterContent: ChapterContentConfig  // 新增：章节内容配置
        
        /// 章节内容配置
        struct ChapterContentConfig {
            let titleSelector: String
            let contentSelector: String
            let nextChapterSelector: String
        }
        
        /// 章节列表配置
        struct ChapterListConfig {
            let container: String?  // 容器选择器（可选）
            let itemPattern: String // 章节项正则
            let titleGroup: Int     // 标题捕获组
            let urlGroup: Int       // URL 捕获组
        }
    }
    
    /// 选择器配置
    struct SelectorConfig {
        let pattern: String      // 正则表达式
        let captureGroup: Int    // 捕获组索引
        let cleanup: ((String) -> String)?  // 清理函数（可选）
        
        init(pattern: String, captureGroup: Int = 1, cleanup: ((String) -> String)? = nil) {
            self.pattern = pattern
            self.captureGroup = captureGroup
            self.cleanup = cleanup
        }
    }
    
    /// 分页配置
    struct PaginationConfig {
        let pageSelectPattern: String  // 分页选择器正则
        let urlTemplate: (String, Int) -> String  // 构建分页 URL
        let maxPages: Int?  // 最大页数限制
    }
}

// MARK: - 预定义配置

extension SiteConfig {
    /// 错层小说网配置
    static let cuoceng = SiteConfig(
        domain: "cuoceng.com",
        name: "错层小说网",
        urlPatterns: URLPatterns(
            bookIdPatterns: [
                "/book/([a-f0-9-]+)/[a-f0-9-]+\\.html",  // 章节页
                "/book/chapter/([a-f0-9-]+)\\.html",      // 目录页
                "/book/([a-f0-9-]+)\\.html"               // 书籍详情页
            ],
            catalogURL: { bookId in
                "https://www.cuoceng.com/book/chapter/\(bookId).html"
            },
            chapterURL: { bookId, chapterId in
                "https://www.cuoceng.com/book/\(bookId)/\(chapterId).html"
            }
        ),
        selectors: Selectors(
            title: SelectorConfig(
                pattern: "<h1>([^<]+)</h1>",
                cleanup: { title in
                    title.replacingOccurrences(of: "\\s*目录\\s*$", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            ),
            author: SelectorConfig(
                pattern: "(?:作者：<a[^>]*>([^<]+)</a>|<a[^>]*class=[\"']author[\"'][^>]*>([^<]+)</a>)",
                captureGroup: 0,  // 特殊处理：多个捕获组
                cleanup: { author in
                    author.replacingOccurrences(of: "\\s*著\\s*$", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            ),
            cover: SelectorConfig(
                pattern: "(?:<input[^>]*id=[\"']bookCover[\"'][^>]*value=[\"']([^\"']+)[\"']|<img[^>]*class=[\"'][^\"']*cover[^\"']*[\"'][^>]*(?:data-src|src)=[\"']([^\"']+)[\"'])"
            ),
            intro: SelectorConfig(
                pattern: "<div[^>]*class=[\"'][^\"']*intro[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>"
            ),
            chapterList: Selectors.ChapterListConfig(
                container: nil,
                itemPattern: "<a href=\"/book/([a-f0-9-]+)/([a-f0-9-]+)\\.html\">\\s*<span[^>]*>([^<]+)</span>\\s*</a>",
                titleGroup: 3,
                urlGroup: 0  // 需要组合 bookId 和 chapterId
            ),
            chapterContent: Selectors.ChapterContentConfig(
                titleSelector: "h1",
                contentSelector: "#readcontent",
                nextChapterSelector: "a.next"
            )
        ),
        pagination: nil
    )
    
    /// 零点看书配置
    static let lingdian = SiteConfig(
        domain: "23txtv.com",
        name: "零点看书",
        urlPatterns: URLPatterns(
            bookIdPatterns: [
                "/ldks/(\\d+)/\\d+\\.html",      // 章节页
                "/ldks/(\\d+)/index_\\d+\\.html", // 目录分页
                "/ldks/(\\d+)/?$"                 // 目录首页
            ],
            catalogURL: { bookId in
                "http://23.225.143.232/ldks/\(bookId)/"
            },
            chapterURL: { bookId, chapterId in
                "http://23.225.143.232/ldks/\(bookId)/\(chapterId).html"
            }
        ),
        selectors: Selectors(
            title: SelectorConfig(
                pattern: "<h1>([^<]+)</h1>"
            ),
            author: SelectorConfig(
                pattern: "<p>作者：([^<]+)</p>"
            ),
            cover: SelectorConfig(
                pattern: "<img[^>]*(?:src=[\"']([^\"']+)[\"'][^>]*alt|alt=[\"'][^\"']*[\"'][^>]*src=[\"']([^\"']+)[\"'])",
                captureGroup: 0  // 多个捕获组
            ),
            intro: SelectorConfig(
                pattern: "<div[^>]*class=[\"'][^\"']*desc[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
                cleanup: { intro in
                    // 移除 "简介:" 标签
                    intro.replacingOccurrences(of: "<strong>简介:</strong>", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            ),
            chapterList: Selectors.ChapterListConfig(
                container: "《[^》]+》正文</h2>[\\s\\S]*?<ul[^>]*class=[\"']section-list[^\"']*[\"'][^>]*>([\\s\\S]*?)</ul>",
                itemPattern: "<li><a href=[\"']([^\"']+)[\"']>([^<]+)</a></li>",
                titleGroup: 2,
                urlGroup: 1
            ),
            chapterContent: Selectors.ChapterContentConfig(
                titleSelector: "h1.title",
                contentSelector: "#content",
                nextChapterSelector: "a"
            )
        ),
        pagination: PaginationConfig(
            pageSelectPattern: "<option value=[\"']([^\"']+)[\"'][^>]*>",
            urlTemplate: { bookId, page in
                if page == 1 {
                    return "http://23.225.143.232/ldks/\(bookId)/"
                } else {
                    return "http://23.225.143.232/ldks/\(bookId)/index_\(page).html"
                }
            },
            maxPages: 50  // 限制最大页数
        )
    )
    
    /// 根据 URL 获取配置
    static func config(for url: String) -> SiteConfig? {
        if url.contains("cuoceng.com") {
            return .cuoceng
        } else if url.contains("23.225.143.232") || url.contains("23txtv.com") {
            return .lingdian
        }
        return nil
    }
}
