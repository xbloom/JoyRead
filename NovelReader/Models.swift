import Foundation

// MARK: - Domain Models (领域模型)

/// 小说完整信息
public struct Novel: Identifiable, Codable {
    public let id: String  // bookId
    public var title: String
    public var author: String?
    public var coverURL: String?
    public var introduction: String?
    public let catalogURL: String
    public var chapters: [Chapter]
    
    // 阅读进度
    public var currentChapterURL: String?
    public var currentChapterTitle: String?
    public var lastReadDate: Date
    
    // 解析配置
    public var parserConfig: ParserConfig
    
    public init(id: String, title: String, author: String? = nil, coverURL: String? = nil,
                introduction: String? = nil, catalogURL: String, chapters: [Chapter],
                currentChapterURL: String? = nil, currentChapterTitle: String? = nil,
                lastReadDate: Date = Date(), parserConfig: ParserConfig = .default) {
        self.id = id
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.introduction = introduction
        self.catalogURL = catalogURL
        self.chapters = chapters
        self.currentChapterURL = currentChapterURL
        self.currentChapterTitle = currentChapterTitle
        self.lastReadDate = lastReadDate
        self.parserConfig = parserConfig
    }
}

/// 章节信息
public struct Chapter: Identifiable, Codable, Hashable {
    public let id: String  // chapterId
    public let title: String
    public let url: String
    
    public init(id: String, title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}

/// 解析器配置
public struct ParserConfig: Codable {
    public var titleSelector: String
    public var contentSelector: String
    public var nextChapterSelector: String
    
    public static let `default` = ParserConfig(
        titleSelector: "h1",
        contentSelector: "#readcontent",
        nextChapterSelector: "a.next"
    )
    
    public init(titleSelector: String, contentSelector: String, nextChapterSelector: String) {
        self.titleSelector = titleSelector
        self.contentSelector = contentSelector
        self.nextChapterSelector = nextChapterSelector
    }
}

/// 章节内容
public struct ChapterContent {
    public let title: String?
    public let content: String
    public let nextChapterURL: String?
    
    public init(title: String?, content: String, nextChapterURL: String?) {
        self.title = title
        self.content = content
        self.nextChapterURL = nextChapterURL
    }
}
