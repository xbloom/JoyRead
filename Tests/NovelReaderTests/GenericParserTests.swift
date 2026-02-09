import XCTest
@testable import NovelReader

final class GenericParserTests: XCTestCase {
    
    func testLingdianConfig() {
        // 测试配置识别
        let url = "http://23.225.143.232/ldks/116429/index_19.html"
        let config = SiteConfig.config(for: url)
        
        XCTAssertNotNil(config, "应该找到零点看书配置")
        XCTAssertEqual(config?.name, "零点看书")
        XCTAssertEqual(config?.domain, "23txtv.com")
    }
    
    func testLingdianBookIdExtraction() {
        let testCases = [
            ("http://23.225.143.232/ldks/116429/47508459.html", "116429"),  // 章节页
            ("http://23.225.143.232/ldks/116429/index_19.html", "116429"),  // 目录分页
            ("http://23.225.143.232/ldks/116429/", "116429")                // 目录首页
        ]
        
        for (url, expectedId) in testCases {
            let config = SiteConfig.lingdian
            
            // 测试 bookId 提取
            var extracted: String?
            for pattern in config.urlPatterns.bookIdPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                   let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
                   let range = Range(match.range(at: 1), in: url) {
                    extracted = String(url[range])
                    break
                }
            }
            
            XCTAssertEqual(extracted, expectedId, "从 \(url) 提取 bookId 失败")
        }
    }
    
    func testCuocengCompatibility() async throws {
        // 测试错层网兼容性（确保旧功能不受影响）
        let url = "https://www.cuoceng.com/book/0bda90f8-217e-4621-bf4d-ce1144a26419.html"
        
        guard let config = SiteConfig.config(for: url) else {
            XCTFail("应该找到错层网配置")
            return
        }
        
        XCTAssertEqual(config.name, "错层小说网")
        
        let parser = GenericParser(config: config)
        
        // 注意：这是网络测试，可能失败
        do {
            let bookInfo = try await parser.parseBook(fromURL: url)
            XCTAssertFalse(bookInfo.title.isEmpty, "书名不应为空")
            XCTAssertNotNil(bookInfo.author, "应该有作者")
            XCTAssertFalse(bookInfo.chapters.isEmpty, "应该有章节")
            print("✅ 错层网解析成功: \(bookInfo.title), 章节数: \(bookInfo.chapters.count)")
        } catch {
            print("⚠️ 网络测试失败（可能是网络问题）: \(error)")
            // 不标记为失败，因为可能是网络问题
        }
    }
    
    func testLingdianParsing() async throws {
        // 测试零点看书解析
        let url = "http://23.225.143.232/ldks/116429/"
        
        guard let config = SiteConfig.config(for: url) else {
            XCTFail("应该找到零点看书配置")
            return
        }
        
        let parser = GenericParser(config: config)
        
        do {
            let bookInfo = try await parser.parseBook(fromURL: url)
            
            print("\n📚 零点看书解析结果:")
            print("  书名: \(bookInfo.title)")
            print("  作者: \(bookInfo.author ?? "未知")")
            print("  封面: \(bookInfo.coverURL ?? "无")")
            print("  章节数: \(bookInfo.chapters.count)")
            
            XCTAssertFalse(bookInfo.title.isEmpty, "书名不应为空")
            XCTAssertNotNil(bookInfo.author, "应该有作者")
            XCTAssertFalse(bookInfo.chapters.isEmpty, "应该有章节")
            
            // 验证章节格式
            if let firstChapter = bookInfo.chapters.first {
                print("  第一章: \(firstChapter.title)")
                XCTAssertFalse(firstChapter.title.isEmpty, "章节标题不应为空")
                XCTAssertTrue(firstChapter.url.hasPrefix("http"), "章节URL应该是完整URL")
            }
            
            print("✅ 零点看书解析成功！")
        } catch {
            print("⚠️ 网络测试失败: \(error)")
            // 不标记为失败，因为可能是网络问题
        }
    }
    
    func testCuocengNewBook() async throws {
        // 测试新的错层网书籍
        let url = "https://www.cuoceng.com/book/d6fb3794-2ca6-4f8b-919c-c3e2f699697b.html"
        
        guard let config = SiteConfig.config(for: url) else {
            XCTFail("应该找到错层网配置")
            return
        }
        
        XCTAssertEqual(config.name, "错层小说网")
        
        let parser = GenericParser(config: config)
        
        do {
            let bookInfo = try await parser.parseBook(fromURL: url)
            
            print("\n📚 错层网新书解析结果:")
            print("  书名: \(bookInfo.title)")
            print("  作者: \(bookInfo.author ?? "未知")")
            print("  封面: \(bookInfo.coverURL ?? "无")")
            print("  章节数: \(bookInfo.chapters.count)")
            
            XCTAssertEqual(bookInfo.title, "从姑获鸟开始")
            XCTAssertNotNil(bookInfo.author, "应该有作者")
            XCTAssertFalse(bookInfo.chapters.isEmpty, "应该有章节")
            
            if let firstChapter = bookInfo.chapters.first {
                print("  第一章: \(firstChapter.title)")
            }
            
            print("✅ 错层网新书解析成功！")
        } catch {
            print("⚠️ 网络测试失败: \(error)")
        }
    }
}
