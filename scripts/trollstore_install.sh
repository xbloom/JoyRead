#!/bin/bash

# TrollStore 一键安装脚本
# 构建 IPA → 生成安装页面 → 启动服务器

set -e

# 切换到项目根目录
cd "$(dirname "$0")/.."

IPA_NAME="NovelReaderApp.ipa"
EXPORT_PATH="build"
PORT=8000

# 1. 调用构建脚本
./scripts/build_ipa.sh

echo ""

# 2. 获取本机 IP
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

# 3. 生成安装页面
cat > "$EXPORT_PATH/index.html" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NovelReader 安装</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
        }
        h1 {
            font-size: 32px;
            margin-bottom: 10px;
            color: #333;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 18px;
            margin: 15px 0;
            border: none;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn:active {
            transform: scale(0.98);
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        .btn-secondary {
            background: #f0f0f0;
            color: #333;
        }
        .steps {
            text-align: left;
            margin-top: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 12px;
        }
        .steps h3 {
            margin-bottom: 15px;
            color: #333;
        }
        .steps ol {
            margin-left: 20px;
        }
        .steps li {
            margin: 10px 0;
            color: #666;
            line-height: 1.6;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        .info {
            margin-top: 20px;
            padding: 15px;
            background: #e3f2fd;
            border-radius: 8px;
            font-size: 14px;
            color: #1976d2;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">📚</div>
        <h1>NovelReader</h1>
        <p class="subtitle">iOS 小说阅读器</p>
        
        <a href="apple-magnifier://install?url=http://${IP}:${PORT}/${IPA_NAME}" class="btn btn-primary">
            🚀 一键安装到 TrollStore
        </a>
        
        <a href="${IPA_NAME}" class="btn btn-secondary" download>
            📥 下载 IPA 文件
        </a>
        
        <div class="info">
            💡 需要先安装 TrollStore
        </div>
        
        <div class="steps">
            <h3>📱 安装步骤</h3>
            <ol>
                <li>确保已安装 TrollStore</li>
                <li>点击"一键安装"按钮</li>
                <li>在弹出的 TrollStore 中点击 Install</li>
                <li>完成！应用会出现在主屏幕</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF

# 4. 生成安装链接
WEB_URL="http://${IP}:${PORT}/"

# 5. 自动复制链接到剪贴板
echo "$WEB_URL" | pbcopy
echo "✅ 安装链接已复制到剪贴板"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 iPad 安装步骤："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "方式1（最快）：通用剪贴板"
echo "  iPad Safari 地址栏长按 → 粘贴并访问"
echo ""
echo "方式2：手动输入"
echo "  ${WEB_URL}"
echo ""
echo "方式3：扫描下方二维码"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 6. 生成二维码（如果安装了 qrencode）
if command -v qrencode &> /dev/null; then
    echo "📷 扫描二维码快速访问："
    echo ""
    qrencode -t ANSIUTF8 "$WEB_URL"
    echo ""
else
    echo "💡 提示：安装 qrencode 可显示二维码"
    echo "   brew install qrencode"
    echo ""
fi

# 7. 自动打开浏览器（可选）
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🌐 正在打开浏览器..."
    sleep 1
    open "$WEB_URL" 2>/dev/null || true
fi

# 8. 启动 HTTP 服务器
echo "🌐 服务器已启动"
echo "   按 Ctrl+C 停止服务器"
echo ""

cd "$EXPORT_PATH"
python3 -m http.server $PORT 2>/dev/null
