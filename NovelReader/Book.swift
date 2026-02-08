import Foundation

struct Book: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String?
    var coverURL: String?
    var currentChapterURL: String
    var currentChapterTitle: String?
    var lastReadDate: Date
    
    // CSS选择器配置
    var titleSelector: String
    var contentSelector: String
    var nextChapterSelector: String
    
    // 目录URL
    var catalogURL: String?
    
    init(id: UUID = UUID(),
         title: String,
         author: String? = nil,
         coverURL: String? = nil,
         currentChapterURL: String,
         currentChapterTitle: String? = nil,
         lastReadDate: Date = Date(),
         titleSelector: String = "h1",
         contentSelector: String = "#readcontent",
         nextChapterSelector: String = "a.next",
         catalogURL: String? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.currentChapterURL = currentChapterURL
        self.currentChapterTitle = currentChapterTitle
        self.lastReadDate = lastReadDate
        self.titleSelector = titleSelector
        self.contentSelector = contentSelector
        self.nextChapterSelector = nextChapterSelector
        self.catalogURL = catalogURL
    }
}
