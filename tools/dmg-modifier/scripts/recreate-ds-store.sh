#!/bin/bash
# 重新制作正确的.DS_Store模板
# 解决背景图路径问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[步骤]${NC} $1"; }

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"
TEMP_DMG="$TOOL_DIR/temp-template.dmg"
VOL_NAME="macsiwen.com"

echo "================================"
echo "  重新制作.DS_Store模板"
echo "  解决背景图路径问题"
echo "================================"
echo ""

# 1. 创建临时DMG
print_step "1. 创建临时DMG作为模板"
if [ -f "$TEMP_DMG" ]; then
    print_warn "删除旧的临时DMG"
    rm -f "$TEMP_DMG"
fi

hdiutil create -size 200m -fs HFS+ -volname "$VOL_NAME" "$TEMP_DMG"
print_info "✅ 临时DMG创建完成"

# 2. 挂载DMG
print_step "2. 挂载DMG"
hdiutil attach "$TEMP_DMG"
sleep 1

MOUNT_POINT="/Volumes/$VOL_NAME"
if [ ! -d "$MOUNT_POINT" ]; then
    print_error "挂载失败：$MOUNT_POINT 不存在"
    exit 1
fi
print_info "✅ DMG已挂载到: $MOUNT_POINT"

# 3. 让用户选择背景图
print_step "3. 选择背景图文件"
echo ""
print_info "请在弹出的对话框中选择背景图文件（支持 PNG/JPG）"

# 使用AppleScript选择文件
SELECTED_BG=$(osascript 2>/dev/null <<EOF
set bgFile to choose file with prompt "选择DMG背景图（PNG或JPG格式）" of type {"public.png", "public.jpeg"}
return POSIX path of bgFile
EOF
)

if [ -z "$SELECTED_BG" ] || [ ! -f "$SELECTED_BG" ]; then
    print_error "未选择背景图或文件不存在"
    hdiutil detach "$MOUNT_POINT" -force 2>/dev/null || true
    exit 1
fi

print_info "已选择背景图: $SELECTED_BG"

# 4. 复制背景图到DMG内部并统一命名
print_step "4. 将背景图复制到DMG内部"
BG_DIR="$MOUNT_POINT/.DropDMGBackground"
mkdir -p "$BG_DIR"

# 统一命名为 background.png（与 modify-dmg.sh 保持一致）
BG_FILENAME="background.png"

# 检查文件格式
BG_EXT="${SELECTED_BG##*.}"
if [[ "$BG_EXT" != "png" ]]; then
    print_warn "背景图不是PNG格式（${BG_EXT}），建议使用PNG以获得最佳兼容性"
    print_info "正在复制并重命名为 background.png..."
fi

cp "$SELECTED_BG" "$BG_DIR/$BG_FILENAME"
print_info "✅ 背景图已复制到DMG内部: $BG_DIR/$BG_FILENAME"
ls -lh "$BG_DIR/$BG_FILENAME"

# 同时复制到模板目录（供 modify-dmg.sh 使用）
cp "$SELECTED_BG" "$TEMPLATES_DIR/$BG_FILENAME"
print_info "✅ 背景图已保存到模板目录: $TEMPLATES_DIR/$BG_FILENAME"

# 5. 添加示例文件（用于布局）
print_step "5. 添加示例文件"
touch "$MOUNT_POINT/应用程序.app"
touch "$MOUNT_POINT/访问macsiwen.cc.webloc"
print_info "✅ 示例文件已添加"

# 6. 使用AppleScript自动配置Finder显示设置
print_step "6. 自动配置Finder显示设置"
echo ""
print_info "正在自动配置背景图、窗口大小和布局..."

# 关键：使用DMG内部文件的POSIX路径，而不是相对路径
BG_INTERNAL_PATH="$MOUNT_POINT/.DropDMGBackground/background.png"

# 使用AppleScript设置（引用DMG内部的文件）
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1300, 700}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set background picture of viewOptions to POSIX file "$BG_INTERNAL_PATH"
        delay 2
        close
        delay 1
    end tell
end tell
EOF

if [ $? -eq 0 ]; then
    print_info "✅ Finder显示设置已自动配置"
    print_info "   - 背景图: $BG_INTERNAL_PATH"
    print_info "   - 窗口大小: 900x600"
    print_info "   - 图标大小: 100"
else
    print_warn "⚠️ 自动配置失败，需要手动设置"
    open "$MOUNT_POINT"
    echo -n "手动配置完成后，按 Enter 继续..."
    read
fi

sleep 2

# 7. 提取.DS_Store
print_step "7. 提取新的.DS_Store文件"
if [ -f "$MOUNT_POINT/.DS_Store" ]; then
    # 备份旧的.DS_Store
    if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        cp "$TEMPLATES_DIR/.DS_Store" "$TEMPLATES_DIR/.DS_Store.backup_$TIMESTAMP"
        print_info "旧的.DS_Store已备份"
    fi
    
    # 复制新的.DS_Store
    cp "$MOUNT_POINT/.DS_Store" "$TEMPLATES_DIR/.DS_Store"
    print_info "✅ 新的.DS_Store已保存到模板目录"
    
    # 显示文件信息
    ls -lh "$TEMPLATES_DIR/.DS_Store"
    
    # 验证路径
    echo ""
    print_info "验证.DS_Store中的路径:"
    strings "$TEMPLATES_DIR/.DS_Store" | grep -E "(background|DropDMG)" | head -5
else
    print_error ".DS_Store文件未生成！"
    print_warn "可能原因：未正确关闭Finder窗口或未设置背景图"
    hdiutil detach "$MOUNT_POINT" -force 2>/dev/null || true
    exit 1
fi

# 8. 卸载并清理
print_step "8. 卸载并清理"
hdiutil detach "$MOUNT_POINT" -force
sleep 1
rm -f "$TEMP_DMG"
print_info "✅ 清理完成"

echo ""
echo "================================"
echo "  ✅ .DS_Store模板重新制作完成！"
echo "================================"
echo ""
print_info "现在可以使用新的.DS_Store模板重新生成DMG了"
print_info "执行: tools/dmg-modifier/scripts/modify-dmg.sh <your-dmg>"