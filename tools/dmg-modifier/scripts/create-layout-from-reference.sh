#!/bin/bash
# 从参考DMG创建自定义布局
# 复用原DMG所有文件，只替换引导页面

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
OUTPUT_PATH="$HOME/Desktop/macsiwen-layout-template.dmg"
MOUNT_POINT="/Volumes/macsiwen.com"

echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════╗
║   从参考DMG创建自定义布局            ║
║   复用所有功能，只改引导页面          ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <参考DMG文件>"
    echo ""
    echo "示例:"
    echo "  $0 'iShot Pro 2.5.8.dmg'"
    echo "  $0 '/path/to/某个软件.dmg'"
    echo ""
    exit 1
fi

REFERENCE_DMG="$1"

if [ ! -f "$REFERENCE_DMG" ]; then
    print_warn "文件不存在: $REFERENCE_DMG"
    exit 1
fi

print_info "参考DMG: $(basename "$REFERENCE_DMG")"
echo ""

# 1. 转换参考DMG为可读写格式
print_info "步骤1: 转换参考DMG为可读写格式..."
TEMP_DMG="$HOME/Desktop/temp-reference.dmg"
hdiutil convert "$REFERENCE_DMG" -format UDRW -o "$TEMP_DMG" -quiet

# 2. 挂载参考DMG
print_info "步骤2: 挂载参考DMG..."
REFERENCE_MOUNT=$(hdiutil attach "$TEMP_DMG" | grep "/Volumes/" | awk '{print $3}')

if [ -z "$REFERENCE_MOUNT" ]; then
    print_warn "挂载失败"
    rm "$TEMP_DMG"
    exit 1
fi

print_info "参考DMG挂载点: $REFERENCE_MOUNT"

# 3. 创建新的可编辑DMG
print_info "步骤3: 创建新的可编辑DMG..."
hdiutil create \
  -volname "macsiwen.com" \
  -size 500m \
  -fs HFS+ \
  -format UDRW \
  "$OUTPUT_PATH" \
  -quiet

# 4. 挂载新DMG
print_info "步骤4: 挂载新DMG..."
hdiutil attach "$OUTPUT_PATH" -mountpoint "$MOUNT_POINT" -quiet

# 5. 复制所有文件（除了.DS_Store和.background）
print_info "步骤5: 复制所有功能文件..."
rsync -av --exclude='.DS_Store' --exclude='.background' "$REFERENCE_MOUNT/" "$MOUNT_POINT/"

print_info "✅ 已复制所有文件"

# 6. 创建.background目录并复制品牌背景图
print_info "步骤6: 设置品牌背景图..."
mkdir -p "$MOUNT_POINT/.background"

if [ -f "$TEMPLATES_DIR/background.png" ]; then
    cp "$TEMPLATES_DIR/background.png" "$MOUNT_POINT/.background/"
    print_info "✅ 品牌背景图已复制"
else
    print_warn "背景图不存在: $TEMPLATES_DIR/background.png"
fi

# 7. 添加品牌文件
print_info "步骤7: 添加品牌文件..."

if [ -f "$TEMPLATES_DIR/qrcode.jpg" ]; then
    cp "$TEMPLATES_DIR/qrcode.jpg" "$MOUNT_POINT/"
    print_info "✅ 二维码已添加"
fi

if [ -f "$TEMPLATES_DIR/官网.webloc" ]; then
    cp "$TEMPLATES_DIR/官网.webloc" "$MOUNT_POINT/"
    print_info "✅ 官网链接已添加"
fi

if [ -f "$TEMPLATES_DIR/macsiwen.txt" ]; then
    cp "$TEMPLATES_DIR/macsiwen.txt" "$MOUNT_POINT/"
    print_info "✅ 品牌说明已添加"
fi

# 8. 卸载参考DMG
print_info "步骤8: 清理临时文件..."
hdiutil detach "$REFERENCE_MOUNT" -quiet
rm "$TEMP_DMG"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 准备完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_info "新DMG位置: $OUTPUT_PATH"
print_info "挂载点: $MOUNT_POINT"
echo ""
print_warn "📝 接下来请设计你的自定义引导页面："
echo ""
echo "1️⃣  在Finder中打开: $MOUNT_POINT"
echo ""
echo "2️⃣  右键空白处 → 显示视图选项："
echo "   - 图标大小: 128×128"
echo "   - 排列方式: 无（重要！）"
echo "   - 网格间距: 适中"
echo ""
echo "3️⃣  设置背景图："
echo "   - 背景: 图片"
echo "   - 拖拽 .background/background.png 到背景栏"
echo ""
echo "4️⃣  调整窗口大小："
echo "   - 拖动右下角到合适大小"
echo "   - 建议: 1200×800 或 1440×900"
echo ""
echo "5️⃣  设计你的布局："
echo "   - 拖拽摆放所有元素到理想位置"
echo "   - 软件.app、Applications、安装教程、修复工具等"
echo "   - 二维码、官网链接等品牌元素"
echo ""
echo "6️⃣  完成后，运行提取脚本："
echo "   cd tools/dmg-modifier/scripts"
echo "   ./extract-ds-store.sh"
echo ""
print_warn "⚠️  设计完成前，请保持DMG挂载状态！"
echo ""
