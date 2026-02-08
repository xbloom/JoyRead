# NovelReader 开发文档

## 项目简介

iOS 小说阅读器，支持从网页解析小说内容，带书架管理、目录导航、章节缓存和预下载功能。

## 快速开始

```bash
# 安装到 iPad
make install

# 运行测试
make test

# 清理构建
make clean
```

## 核心功能

### 书架管理
- 📚 书架首页显示所有小说
- ➕ 粘贴任意章节URL自动添加书籍（自动获取书名、作者、目录）
- 📖 点击小说继续阅读
- 💾 自动保存阅读进度
- 🗑️ 删除小说
- 🕐 按最后阅读时间排序

### 阅读功能
- 从网页 URL 解析小说章节
- 支持两种解析模式：
  - 正则表达式（快速）
  - WebView（兼容性好）
- 章节导航（上一章/下一章）
- 自定义 CSS 选择器

### 目录功能
- 📑 显示完整章节列表
- 🔵 标记当前阅读位置
- 🟢 显示已缓存章节
- 🔄 刷新缓存状态
- 📊 显示缓存统计（X/总数 章已缓存）

### 缓存与下载
- 💾 **自动缓存**：阅读过的章节自动缓存到本地
- 🚀 **智能预下载**：自动预下载后续3章，保证流畅阅读
- 📥 **批量下载**：
  - 下载全书
  - 下载后续50章
- 📊 **下载管理**：
  - 显示已缓存章节数和缓存大小
  - 实时显示下载进度
  - 支持取消下载
- 🗑️ **缓存管理**：清空所有缓存

## 项目结构

```
NovelReader/                      # iOS 应用代码
├── NovelReaderApp.swift          # 入口
├── BookshelfView.swift           # 书架界面
├── BookshelfViewModel.swift      # 书架数据管理
├── Book.swift                    # 书籍数据模型
├── ReaderView.swift              # 阅读器界面
├── NovelReaderViewModel.swift    # 阅读器业务逻辑
├── CatalogView.swift             # 目录界面
├── CatalogViewModel.swift        # 目录数据管理
├── DownloadView.swift            # 下载管理界面
├── DownloadManager.swift         # 下载管理器
├── ChapterCacheManager.swift     # 章节缓存管理
├── ContentView.swift             # 原阅读器UI（已废弃）
└── HTMLParser.swift              # 核心：HTML 解析

Tests/                            # 测试代码
└── NovelReaderTests/
    ├── HTMLParserTests.swift     # 章节解析测试
    └── CatalogParserTests.swift  # 目录解析测试

Package.swift                     # Swift Package 配置
Makefile                          # 构建脚本
```

## 使用流程

1. 启动应用 → 显示书架
2. 点击右上角 ➕ → 添加小说
3. 粘贴任意章节URL（如：`https://www.cuoceng.com/book/xxx/yyy.html`）
4. 自动解析书名、作者、目录 → 添加到书架
5. 点击书籍 → 开始阅读
6. 阅读时自动缓存当前章节 + 预下载后续3章
7. 点击"目录"查看所有章节（绿色图标=已缓存）
8. 点击右上角 ⋯ → "下载管理" → 批量下载

## 数据持久化

### UserDefaults
- 书籍列表
- 当前阅读章节URL
- 章节标题
- 最后阅读时间
- CSS选择器配置
- 目录URL

### 文件系统缓存
- 位置：`~/Library/Caches/ChapterCache/`
- 格式：JSON 文件（使用URL的MD5作为文件名）
- 内容：章节标题、内容、下一章URL、缓存时间

## 预下载逻辑

### 触发时机
1. 从网络加载章节成功后
2. 从缓存读取章节后

### 预下载策略
- 预下载后续 **3 章**（可配置）
- 如果某章已缓存，跳过但继续下载下一章
- 每章间隔 0.3 秒，避免请求过快
- 后台异步执行，不阻塞主线程
- 失败静默处理，不影响用户体验

### 效果
- 用户阅读时，后续3章始终保持缓存
- 点击"下一章"基本秒开
- 离线也能阅读已缓存章节

## 开发要求

- iOS 15.0+
- Swift 6.2.1
- Xcode 17+
- macOS 12.0+（用于运行测试）

## 测试

详见 `Tests/dev.md`

测试覆盖：
- ✅ 章节内容解析（正则模式）
- ✅ 章节内容解析（WebView模式）
- ✅ 目录解析（书籍信息 + 章节列表）
- ✅ URL格式验证
- ✅ 错误处理

## 默认配置

- 标题选择器：`h1`
- 内容选择器：`#readcontent`
- 下一章选择器：`a.next`
- 解析模式：正则表达式
- 预下载数量：3章

## 支持的网站

目前针对 `cuoceng.com` 优化，支持：
- 章节URL格式：`/book/{bookId}/{chapterId}.html`
- 目录URL格式：`/book/chapter/{bookId}.html`

其他网站可通过自定义CSS选择器支持。
