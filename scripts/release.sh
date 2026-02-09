#!/bin/bash

# 发布新版本脚本

set -e

if [ -z "$1" ]; then
    echo "用法: ./scripts/release.sh <version>"
    echo "示例: ./scripts/release.sh v1.0.0"
    exit 1
fi

VERSION=$1

echo "📦 准备发布 JoyRead $VERSION"
echo ""

# 1. 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    echo "❌ 有未提交的更改，请先提交"
    git status -s
    exit 1
fi

# 2. 创建 tag
echo "🏷️  创建 tag: $VERSION"
git tag -a "$VERSION" -m "Release $VERSION"

# 3. 推送到 GitHub
echo "⬆️  推送到 GitHub..."
git push origin main
git push origin "$VERSION"

echo ""
echo "✅ 发布完成！"
echo ""
echo "GitHub Actions 将自动构建 IPA"
echo "查看进度: https://github.com/YOUR_USERNAME/YOUR_REPO/actions"
echo ""
echo "构建完成后，IPA 将出现在:"
echo "https://github.com/YOUR_USERNAME/YOUR_REPO/releases/tag/$VERSION"
