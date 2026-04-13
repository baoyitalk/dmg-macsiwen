#!/bin/bash
# 创建可编辑的模板DMG
# 用于设计自定义引导页面布局

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[提示]${NC} $1"
}

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"
OUTPUT_PATH="$HOME/Desktop/macsiwen-template.dmg"
MOUNT_POINT="/Volumes/macsiwen.com"

echo "================================"
echo "  创建macsiwen模板DMG"
echo "  用于自定义引导页面布局"
echo "================================"
echo ""

# 1. 创建空白DMG（可读写）
print_info "步骤1: 创建空白DMG（500MB，可读写）..."
hdiutil create \
  -volname "macsiwen.com" \
  -size 500m \
  -fs HFS+ \
  -format UDRW \
  "$OUTPUT_PATH"

# 2. 挂载DMG
print_info "步骤2: 挂载DMG..."
hdiutil attach "$OUTPUT_PATH" -mountpoint "$MOUNT_POINT"

# 3. 创建.background目录并复制背景图
print_info "步骤3: 复制品牌素材..."
mkdir -p "$MOUNT_POINT/.background"

if [ -f "$TEMPLATES_DIR/background.png" ]; then
    cp "$TEMPLATES_DIR/background.png" "$MOUNT_POINT/.background/"
    print_info "✅ 背景图已复制"
else
    print_warn "背景图不存在，将使用纯色背景"
fi

# 4. 复制二维码
if [ -f "$TEMPLATES_DIR/qrcode.jpg" ]; then
    cp "$TEMPLATES_DIR/qrcode.jpg" "$MOUNT_POINT/"
    print_info "✅ 二维码已复制"
fi

# 5. 复制官网链接
if [ -f "$TEMPLATES_DIR/官网.webloc" ]; then
    cp "$TEMPLATES_DIR/官网.webloc" "$MOUNT_POINT/"
    print_info "✅ 官网链接已复制"
fi

# 6. 创建品牌说明文件
if [ -f "$TEMPLATES_DIR/macsiwen.txt" ]; then
    cp "$TEMPLATES_DIR/macsiwen.txt" "$MOUNT_POINT/"
    print_info "✅ 品牌说明已复制"
fi

# 7. 创建Applications快捷方式
print_info "步骤4: 创建Applications快捷方式..."
ln -s /Applications "$MOUNT_POINT/Applications"

# 8. 创建示例App（占位符）
print_info "步骤5: 创建示例App占位符..."
mkdir -p "$MOUNT_POINT/示例软件.app/Contents/MacOS"
echo "#!/bin/bash" > "$MOUNT_POINT/示例软件.app/Contents/MacOS/示例软件"
chmod +x "$MOUNT_POINT/示例软件.app/Contents/MacOS/示例软件"

# 创建Info.plist
cat > "$MOUNT_POINT/示例软件.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>示例软件</string>
    <key>CFBundleIdentifier</key>
    <string>com.macsiwen.example</string>
    <key>CFBundleName</key>
    <string>示例软件</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
EOF

print_info "✅ 示例App已创建"

echo ""
echo "================================"
echo "  ✅ 模板DMG创建完成！"
echo "================================"
echo ""
print_info "DMG位置: $OUTPUT_PATH"
print_info "挂载点: $MOUNT_POINT"
echo ""
print_warn "📝 接下来请按以下步骤操作："
echo ""
echo "1️⃣  复制原DMG的所有文件到模板DMG："
echo "   - 挂载原DMG（如iShot.dmg）"
echo "   - 复制所有文件到 $MOUNT_POINT"
echo "   - 包括：安装教程视频、修复工具、说明文档等"
echo "   - ⚠️  保留原有的所有功能文件！"
echo ""
echo "2️⃣  在Finder中打开: $MOUNT_POINT"
echo ""
echo "3️⃣  右键空白处 → 显示视图选项，设置："
echo "   - 图标大小: 128×128"
echo "   - 网格间距: 适中"
echo "   - 文本大小: 12"
echo "   - 标签位置: 底部"
echo "   - 排列方式: 无"
echo ""
echo "4️⃣  设置背景图："
echo "   - 背景: 图片"
echo "   - 拖拽 .background/background.png 到背景栏"
echo ""
echo "5️⃣  调整窗口大小："
echo "   - 建议: 1200×800 或 1440×900"
echo "   - 拖动窗口右下角调整"
echo ""
echo "6️⃣  摆放所有元素位置："
echo "   - 软件.app → 左侧"
echo "   - Applications快捷方式 → 右侧"
echo "   - 安装教程视频.rtfd → 左下"
echo "   - 修复软件损坏工具 → 右下"
echo "   - 二维码、官网链接等 → 按需摆放"
echo "   - ⚠️  保留原DMG的所有元素！"
echo ""
echo "7️⃣  显示隐藏文件（查看.DS_Store）："
echo "   defaults write com.apple.finder AppleShowAllFiles -bool true"
echo "   killall Finder"
echo ""
echo "8️⃣  完成后，运行提取脚本："
echo "   cd tools/dmg-modifier/scripts"
echo "   ./extract-ds-store.sh"
echo ""
print_warn "⚠️  调整完成前，请保持DMG挂载状态！"
echo ""
