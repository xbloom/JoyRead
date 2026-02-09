import Testing
@testable import NovelReader

@Test("Repository - 添加小说（完整流程）")
func testRepositoryAddNovel() async throws {
    let repository = NovelRepository()
    let testURL = "https://www.cuoceng.com/book/0bda90f8-217e-4621-bf4d-ce1144a26419.html"
    
    // 添加小说
    let novel = try await repository.addNovel(fromURL: testURL)
    
    // 验证小说信息
    #expect(!novel.title.isEmpty, "书名不应为空")
    #expect(novel.author != nil, "应该有作者")
    #expect(novel.coverURL != nil, "应该有封面")
    #expect(!novel.chapters.isEmpty, "应该有章节列表")
    #expect(novel.currentChapterURL != nil, "应该有初始章节")
    
    print("✅ 小说信息:")
    print("  ID: \(novel.id)")
    print("  书名: \(novel.title)")
    print("  作者: \(novel.author ?? "未知")")
    print("  章节数: \(novel.chapters.count)")
    print("  封面: \(novel.coverURL ?? "无")")
}

@Test("Repository - 获取章节内容（带缓存）")
func testRepositoryGetChapter() async throws {
    let repository = NovelRepository()
    let testURL = "https://www.cuoceng.com/book/95e1a104-af57-421b-aa25-e77bdab6e51c/7a84f4f5-85c3-453e-b18d-f8c7f77be9f0.html"
    
    // 第一次获取（从网络）
    let content1 = try await repository.getChapterContent(
        url: testURL,
        config: .default
    )
    
    #expect(content1.content.count > 1000, "内容应该足够长")
    #expect(!content1.content.contains("<"), "内容不应包含HTML标签")
    
    // 验证已缓存
    #expect(repository.isChapterCached(url: testURL), "章节应该已缓存")
    
    // 第二次获取（从缓存）
    let content2 = try await repository.getChapterContent(
        url: testURL,
        config: .default
    )
    
    #expect(content1.content == content2.content, "缓存内容应该一致")
    
    print("✅ 章节内容:")
    print("  长度: \(content1.content.count)")
    print("  已缓存: \(repository.isChapterCached(url: testURL))")
}

@Test("Repository - 数据持久化")
func testRepositoryPersistence() async throws {
    let repository = NovelRepository()
    let testURL = "https://www.cuoceng.com/book/0bda90f8-217e-4621-bf4d-ce1144a26419.html"
    
    // 添加小说
    let novel = try await repository.addNovel(fromURL: testURL)
    
    // 重新创建 repository（模拟应用重启）
    let newRepository = NovelRepository()
    let novels = newRepository.getAllNovels()
    
    // 验证数据已持久化
    #expect(!novels.isEmpty, "应该能读取到保存的小说")
    #expect(novels.contains(where: { $0.id == novel.id }), "应该包含刚添加的小说")
    
    // 清理
    try newRepository.deleteNovel(novel)
    
    print("✅ 数据持久化测试通过")
}
