#!/bin/bash
# 从模板DMG中提取.DS_Store文件
# 用于后续批量处理时应用自定义布局

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[提示]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"
MOUNT_POINT="/Volumes/macsiwen.com"

echo "================================"
echo "  提取.DS_Store文件"
echo "================================"
echo ""

# 检查DMG是否已挂载
if [ ! -d "$MOUNT_POINT" ]; then
    print_error "模板DMG未挂载！"
    print_info "请先运行: ./create-template-dmg.sh"
    exit 1
fi

# 检查.DS_Store是否存在
if [ ! -f "$MOUNT_POINT/.DS_Store" ]; then
    print_error ".DS_Store文件不存在！"
    print_warn "请确保："
    echo "  1. 已在Finder中打开过该DMG"
    echo "  2. 已设置过视图选项"
    echo "  3. 已调整过图标位置"
    exit 1
fi

# 备份旧的.DS_Store（如果存在）
if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
    print_info "备份旧的.DS_Store..."
    mv "$TEMPLATES_DIR/.DS_Store" "$TEMPLATES_DIR/.DS_Store.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 复制.DS_Store
print_info "提取.DS_Store文件..."
cp "$MOUNT_POINT/.DS_Store" "$TEMPLATES_DIR/"

# 验证文件
if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
    FILE_SIZE=$(stat -f%z "$TEMPLATES_DIR/.DS_Store")
    print_info "✅ 提取成功！"
    print_info "文件大小: $FILE_SIZE bytes"
    print_info "保存位置: $TEMPLATES_DIR/.DS_Store"
else
    print_error "提取失败！"
    exit 1
fi

echo ""
print_warn "📝 接下来的步骤："
echo ""
echo "1️⃣  卸载模板DMG："
echo "   hdiutil detach '$MOUNT_POINT'"
echo ""
echo "2️⃣  （可选）删除模板DMG："
echo "   rm ~/Desktop/macsiwen-template.dmg"
echo ""
echo "3️⃣  测试自定义布局："
echo "   ./modify-dmg.sh '某个测试.dmg'"
echo ""
echo "4️⃣  查看处理后的DMG，确认布局正确"
echo ""
print_info "✅ 完成！现在批量处理时会使用你的自定义布局"
echo ""
