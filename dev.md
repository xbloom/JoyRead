# NovelReader 开发文档

## 项目简介

iOS 小说阅读器，支持从网页解析小说内容，带书架管理功能。

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
- ➕ 添加小说到书架
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

## 项目结构

```
NovelReader/                      # iOS 应用代码
├── NovelReaderApp.swift          # 入口
├── BookshelfView.swift           # 书架界面
├── BookshelfViewModel.swift      # 书架数据管理
├── Book.swift                    # 书籍数据模型
├── ReaderView.swift              # 阅读器界面
├── NovelReaderViewModel.swift    # 阅读器业务逻辑
├── ContentView.swift             # 原阅读器UI（已废弃）
└── HTMLParser.swift              # 核心：HTML 解析

Tests/                            # 测试代码
└── NovelReaderTests/

Package.swift                     # Swift Package 配置
Makefile                          # 构建脚本
```

## 使用流程

1. 启动应用 → 显示书架
2. 点击右上角 ➕ → 添加小说
3. 输入小说名称和起始章节URL
4. 配置CSS选择器（可选）
5. 点击"添加到书架"
6. 在书架点击小说 → 开始阅读
7. 阅读进度自动保存

## 数据持久化

使用 `UserDefaults` 存储：
- 书籍列表
- 当前阅读章节URL
- 章节标题
- 最后阅读时间
- CSS选择器配置

## 开发要求

- iOS 15.0+
- Swift 6.2.1
- Xcode 17+

## 测试

详见 `Tests/dev.md`

## 默认配置

- 标题选择器：`h1`
- 内容选择器：`#readcontent`
- 下一章选择器：`a.next`
- 解析模式：正则表达式
