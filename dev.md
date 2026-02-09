# NovelReader 开发文档

## 项目简介

iOS 小说阅读器，支持从网页解析小说内容，带书架管理、目录导航、章节缓存和预下载功能。

## 快速开始

```bash
# TrollStore 安装（推荐）
make trollstore

# 运行测试
make test

# 清理构建
make clean
```

## 核心功能

### 书架管理
- 📚 卡片式网格布局，显示封面、书名、作者
- ➕ 粘贴任意URL（书页/目录页/章节页）自动识别添加
- 🎯 自动提取：书名、作者、封面、章节列表
- 💾 自动保存阅读进度

### 阅读功能
- 🎨 三种主题（白天/护眼/夜间）
- 📝 五种字体，字号/行距/段距可调
- 🚀 智能预下载后续3章
- 📥 批量下载（全书/后续50章）

## 架构设计

### 数据层（可独立测试）
```
Models.swift          → Novel, Chapter, ChapterContent
NovelRepository.swift → 数据仓储（业务逻辑）
DataSource.swift      → 数据源（网络+本地）
```

### 解析层
```
SiteParser.swift      → 解析器协议
CuocengParser.swift   → 错层网实现
  - 统一流程：识别URL → 书页获取详情 → 目录页获取章节
  - 支持：书页/目录页/章节页
```

### 视图层
```
BookshelfView         → 书架（卡片式）
ReaderView            → 阅读器
CatalogView           → 目录
DownloadView          → 下载管理
```

## 数据流

```
用户输入URL
    ↓
Repository.addNovel(url)
    ↓
SiteParser.parseBook(url)
  → 识别URL类型
  → 书页获取：书名、作者、封面
  → 目录页获取：章节列表
    ↓
LocalStorage.save(novel)
    ↓
返回 Novel（包含完整信息）
```

## 测试

```bash
swift test
```

测试覆盖：
- ✅ 解析器：章节/目录解析
- ✅ Repository：完整流程、缓存、持久化
- ✅ 数据层可独立测试

## 支持的网站

**cuoceng.com**（错层小说网）
- 书页：`/book/{bookId}.html`
- 目录页：`/book/chapter/{bookId}.html`
- 章节页：`/book/{bookId}/{chapterId}.html`

添加新网站：实现 `SiteParser` 协议即可。

## 开发要求

- iOS 15.0+
- Swift 6.2.1
- Xcode 17+
