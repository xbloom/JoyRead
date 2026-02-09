#!/bin/bash

# 构建 IPA 文件
# 用途：仅负责构建，不启动服务器

set -e

PROJECT="NovelReaderApp.xcodeproj"
SCHEME="NovelReaderApp"
ARCHIVE_PATH="build/NovelReaderApp.xcarchive"
EXPORT_PATH="build"
IPA_NAME="NovelReaderApp.ipa"

echo "🔨 开始构建 IPA..."

# 1. 清理旧文件
rm -rf build/

# 2. Archive
echo "📦 正在打包..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  DEVELOPMENT_TEAM=49NSXZJZ54 \
  CODE_SIGN_STYLE=Automatic \
  -quiet

# 3. Export IPA
echo "📤 正在导出 IPA..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist scripts/ExportOptions.plist \
  -quiet

# 4. 查找生成的 IPA
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)

if [ -z "$IPA_FILE" ]; then
    echo "❌ 未找到 IPA 文件"
    exit 1
fi

# 5. 重命名为固定名称
mv "$IPA_FILE" "$EXPORT_PATH/$IPA_NAME"

echo "✅ IPA 构建成功: $EXPORT_PATH/$IPA_NAME"
