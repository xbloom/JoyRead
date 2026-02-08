# 测试规范

## 目标

测试核心业务逻辑，确保能正确解析小说内容。

## 运行测试

```bash
make test
```

## 测试框架

使用 Swift Testing 框架（Swift 6.0+）

## 测试原则

1. **测试业务代码**：测试 `HTMLParser`、`ViewModel` 等核心逻辑
2. **不测试 UI**：不测试 SwiftUI 视图
3. **使用真实数据**：直接访问真实网页，不用 mock
4. **快速简洁**：每个测试应在 10 秒内完成

## 编写测试

### 基本格式

```swift
import Testing
@testable import NovelReader

@Test("测试描述")
func testSomething() async throws {
    // 测试代码
    #expect(condition)
}
```

### 断言

- `#expect(condition)` - 验证条件为真
- `#expect(a == b)` - 验证相等
- `#expect(a != b)` - 验证不相等

### 示例

```swift
@Test("解析小说内容")
func testParse() async throws {
    let parser = HTMLParser()
    let result = try await parser.parseNovelPage(...)
    
    #expect(result.content.count > 2000)
    #expect(result.content.contains("关键词"))
}
```

## 当前测试覆盖

- ✅ HTMLParser 正则模式
- ✅ HTMLParser WebView 模式

## 添加新测试

1. 在 `Tests/NovelReaderTests/` 创建测试文件
2. 使用 `@Test` 标记测试函数
3. 运行 `make test` 验证

## 注意事项

- 测试依赖网络，确保能访问测试 URL
- WebView 模式比正则模式慢 5-6 倍
- 测试代码直接使用 `NovelReader/` 目录的业务代码，无副本
