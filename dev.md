# NovelReader 开发文档

## 项目简介

iOS 小说阅读器，支持从网页解析小说内容。

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

- 从网页 URL 解析小说章节
- 支持两种解析模式：
  - 正则表达式（快速）
  - WebView（兼容性好）
- 章节导航（上一章/下一章）
- 自定义 CSS 选择器

## 项目结构

```
NovelReader/              # iOS 应用代码
├── HTMLParser.swift      # 核心：HTML 解析
├── NovelReaderViewModel.swift  # 业务逻辑
├── ContentView.swift     # UI
└── NovelReaderApp.swift  # 入口

Tests/                    # 测试代码
└── NovelReaderTests/

Package.swift             # Swift Package 配置
Makefile                  # 构建脚本
```

## 开发要求

- iOS 15.0+
- Swift 6.2.1
- Xcode 17+

## 测试

详见 `Tests/dev.md`

## 配置

默认配置：
- 标题选择器：`h1`
- 内容选择器：`#readcontent`
- 下一章选择器：`a.next`
- 解析模式：正则表达式
