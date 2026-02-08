import Testing
@testable import NovelReader

@Test("解析目录页面 - 包含书籍信息")
func testParseCatalog() async throws {
    let parser = HTMLParser()
    let catalogURL = "https://www.cuoceng.com/book/chapter/95e1a104-af57-421b-aa25-e77bdab6e51c.html"
    
    let (bookInfo, chapters) = try await parser.parseCatalog(url: catalogURL)
    
    // 验证书籍信息
    #expect(bookInfo.bookId == "95e1a104-af57-421b-aa25-e77bdab6e51c", "bookId应该正确")
    #expect(!bookInfo.title.isEmpty, "书名不应为空")
    #expect(bookInfo.author != nil, "应该有作者信息")
    #expect(bookInfo.catalogURL == catalogURL, "目录URL应该正确")
    
    print("📚 书籍信息:")
    print("  书名: \(bookInfo.title)")
    print("  作者: \(bookInfo.author ?? "未知")")
    print("  bookId: \(bookInfo.bookId)")
    if let coverURL = bookInfo.coverURL {
        print("  封面: \(coverURL)")
    }
    
    // 验证章节列表
    #expect(chapters.count > 5, "应该有多个章节")
    
    // 验证第一个章节
    let firstChapter = chapters.first!
    #expect(!firstChapter.id.isEmpty, "章节ID不应为空")
    #expect(!firstChapter.title.isEmpty, "章节标题不应为空")
    #expect(firstChapter.url.contains("cuoceng.com"), "章节URL应包含域名")
    #expect(firstChapter.url.contains(firstChapter.id), "章节URL应包含章节ID")
    
    // 打印前几个章节
    print("\n📖 章节列表 (共\(chapters.count)章):")
    for (index, chapter) in chapters.prefix(5).enumerated() {
        print("  \(index + 1). \(chapter.title)")
    }
}

@Test("解析目录 - 无效URL")
func testParseCatalogInvalidURL() async {
    let parser = HTMLParser()
    let invalidURL = "not-a-valid-url"
    
    do {
        _ = try await parser.parseCatalog(url: invalidURL)
        #expect(Bool(false), "应该抛出错误")
    } catch {
        // URL错误可能返回不同的错误信息
        #expect(error.localizedDescription.contains("无效") || error.localizedDescription.contains("URL"), "错误信息应包含'无效'或'URL'")
    }
}

@Test("解析目录 - 验证章节格式")
func testParseCatalogChapterFormat() async throws {
    let parser = HTMLParser()
    let catalogURL = "https://www.cuoceng.com/book/chapter/95e1a104-af57-421b-aa25-e77bdab6e51c.html"
    
    let (_, chapters) = try await parser.parseCatalog(url: catalogURL)
    
    // 验证章节格式
    for chapter in chapters.prefix(10) {
        // ID应该是UUID格式
        #expect(chapter.id.contains("-"), "章节ID应该是UUID格式")
        #expect(chapter.id.count > 30, "章节ID长度应该足够")
        
        // 标题不应为空且不应包含HTML标签
        #expect(!chapter.title.isEmpty, "章节标题不应为空")
        #expect(!chapter.title.contains("<"), "章节标题不应包含HTML标签")
        #expect(!chapter.title.contains(">"), "章节标题不应包含HTML标签")
        
        // URL应该是完整的HTTP URL
        #expect(chapter.url.hasPrefix("https://"), "章节URL应该以https://开头")
        #expect(chapter.url.hasSuffix(".html"), "章节URL应该以.html结尾")
    }
}

@Test("解析目录 - 验证bookId提取")
func testParseCatalogExtractBookId() async throws {
    let parser = HTMLParser()
    let catalogURL = "https://www.cuoceng.com/book/chapter/95e1a104-af57-421b-aa25-e77bdab6e51c.html"
    
    let (bookInfo, chapters) = try await parser.parseCatalog(url: catalogURL)
    
    // 验证bookId
    let bookId = "95e1a104-af57-421b-aa25-e77bdab6e51c"
    #expect(bookInfo.bookId == bookId, "bookId应该正确")
    
    // 验证所有章节URL都包含正确的bookId
    for chapter in chapters.prefix(10) {
        #expect(chapter.url.contains(bookId), "章节URL应包含bookId")
    }
}
