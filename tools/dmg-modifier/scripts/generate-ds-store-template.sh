#!/bin/bash
# 自动生成.DS_Store模板
# 用途：只需提供背景图，自动生成正确的.DS_Store模板
# v1.0.0

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "================================"
echo "  自动生成.DS_Store模板"
echo "  v1.0.0"
echo "================================"
echo ""

# 检查背景图是否存在
if [ ! -f "$TEMPLATES_DIR/macsiwen-background.png" ]; then
    print_error "背景图不存在: $TEMPLATES_DIR/macsiwen-background.png"
    print_error "请先将背景图放到templates目录"
    exit 1
fi

print_info "背景图已找到: macsiwen-background.png"
echo ""

# 创建临时DMG
print_info "步骤1: 创建临时DMG..."
TEMP_DMG="$TOOL_DIR/temp-ds-store-template.dmg"

if [ -f "$TEMP_DMG" ]; then
    rm -f "$TEMP_DMG"
fi

hdiutil create -size 200m -fs HFS+ -volname "macsiwen.com" "$TEMP_DMG" > /dev/null
print_info "✅ 临时DMG已创建"
echo ""

# 挂载DMG
print_info "步骤2: 挂载DMG..."
attach_output=$(hdiutil attach "$TEMP_DMG")
mount_point=$(echo "$attach_output" | grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/')
mount_device=$(echo "$attach_output" | grep "/Volumes/" | awk '{print $1}')

if [ -z "$mount_point" ]; then
    print_error "挂载失败"
    exit 1
fi

print_info "✅ DMG已挂载: $mount_point"
echo ""

# 创建背景图目录并复制背景图
print_info "步骤3: 设置背景图..."
mkdir -p "$mount_point/.DropDMGBackground"
cp "$TEMPLATES_DIR/macsiwen-background.png" "$mount_point/.DropDMGBackground/"
print_info "✅ 背景图已复制到DMG内部"
echo ""

# 创建一个测试App图标（用于布局）
print_info "步骤4: 创建测试布局..."
if [ -d "/Applications/2Do.app" ]; then
    cp -R "/Applications/2Do.app" "$mount_point/" 2>/dev/null || true
fi

# 创建Applications链接
ln -s /Applications "$mount_point/Applications" 2>/dev/null || true
print_info "✅ 布局已设置"
echo ""

# 使用AppleScript设置背景和布局
print_info "步骤5: 使用AppleScript设置Finder视图..."
echo ""
print_info "正在设置背景图..."

osascript <<EOF
tell application "Finder"
    tell disk "macsiwen.com"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1300, 700}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set background picture of viewOptions to file ".DropDMGBackground:macsiwen-background.png"
        set position of item "Applications" of container window to {700, 400}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

print_info "✅ Finder视图已设置"
echo ""

# 重要：等待.DS_Store写入磁盘
print_info "步骤6: 等待.DS_Store写入..."
sleep 3
print_info "✅ 写入完成"
echo ""

# 验证.DS_Store
print_info "步骤7: 验证.DS_Store..."
if [ -f "$mount_point/.DS_Store" ]; then
    print_info "✅ .DS_Store已生成"
    
    # 检查引用的路径
    if strings "$mount_point/.DS_Store" | grep -q "Desktop"; then
        print_warn "⚠️  检测到Desktop路径，但可以继续"
    fi
    
    if strings "$mount_point/.DS_Store" | grep -q "DropDMG"; then
        print_info "✅ 检测到DropDMGBackground引用"
    fi
else
    print_error ".DS_Store未生成"
    print_error "请手动操作："
    print_error "  1. 打开 $mount_point"
    print_error "  2. 按 Cmd+J 设置背景图"
    print_error "  3. 关闭窗口"
    exit 1
fi
echo ""

# 提取.DS_Store
print_info "步骤8: 提取.DS_Store到模板目录..."
cp "$mount_point/.DS_Store" "$TEMPLATES_DIR/.DS_Store"
print_info "✅ .DS_Store已复制到: $TEMPLATES_DIR/.DS_Store"
echo ""

# 卸载并清理
print_info "步骤9: 清理临时文件..."
hdiutil detach "$mount_device" -force > /dev/null
rm -f "$TEMP_DMG"
print_info "✅ 清理完成"
echo ""

echo "================================"
echo -e "${GREEN}✅ .DS_Store模板生成成功！${NC}"
echo "================================"
echo ""
echo "现在你可以："
echo "  1. 随时替换 templates/macsiwen-background.png"
echo "  2. 使用Electron处理DMG"
echo "  3. 背景图会自动应用"
echo ""
echo "如果需要重新生成.DS_Store模板："
echo "  ./scripts/generate-ds-store-template.sh"
echo ""