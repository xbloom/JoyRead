import Testing
@testable import NovelReader

@Test("解析小说内容 - 正则模式")
func testParseNovelPageRegex() async throws {
    let parser = HTMLParser()
    let testURL = "https://www.cuoceng.com/book/95e1a104-af57-421b-aa25-e77bdab6e51c/7a84f4f5-85c3-453e-b18d-f8c7f77be9f0.html"
    
    let result = try await parser.parseNovelPage(
        url: testURL,
        titleSelector: "h1",
        contentSelector: "#readcontent",
        nextChapterSelector: "a.next",
        mode: .regex
    )
    
    #expect(result.content.count > 2000)
    #expect(result.content.contains("修司"))
    #expect(result.content.contains("鼬"))
    #expect(result.content != "无法找到内容")
}

@Test("解析小说内容 - WebView模式")
func testParseNovelPageWebView() async throws {
    let parser = HTMLParser()
    let testURL = "https://www.cuoceng.com/book/95e1a104-af57-421b-aa25-e77bdab6e51c/7a84f4f5-85c3-453e-b18d-f8c7f77be9f0.html"
    
    let result = try await parser.parseNovelPage(
        url: testURL,
        titleSelector: "h1",
        contentSelector: "#readcontent",
        nextChapterSelector: "a.next",
        mode: .webView
    )
    
    #expect(result.content.count > 2000)
    #expect(result.content.contains("修司"))
    #expect(result.content.contains("鼬"))
    #expect(result.content != "无法找到内容")
}
