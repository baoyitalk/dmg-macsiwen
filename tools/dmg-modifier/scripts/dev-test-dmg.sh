#!/bin/bash
# DMG修复验收测试脚本（开发模式）
# 用途：快速测试DMG背景图修复效果

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "  DMG背景图修复验收测试"
echo "  v1.1.65 开发模式"
echo "================================"
echo ""

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$TOOL_DIR/output"

# 检查是否提供了DMG文件
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}📋 使用方法：${NC}"
    echo "  $0 <input.dmg>"
    echo ""
    echo -e "${BLUE}💡 示例：${NC}"
    echo "  $0 ~/Downloads/iShot-Pro-2.5.8.dmg"
    echo "  $0 '~/Desktop/测试文件.dmg'"
    echo ""
    echo -e "${YELLOW}📂 或者将DMG文件拖到这里：${NC}"
    read -p "DMG文件路径: " dmg_path
    
    if [ -z "$dmg_path" ]; then
        echo -e "${RED}❌ 未提供DMG文件${NC}"
        exit 1
    fi
else
    dmg_path="$1"
fi

# 展开路径（处理~符号）
dmg_path="${dmg_path/#\~/$HOME}"

# 检查文件是否存在
if [ ! -f "$dmg_path" ]; then
    echo -e "${RED}❌ 文件不存在: $dmg_path${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 找到DMG文件${NC}"
echo "   路径: $dmg_path"
echo "   大小: $(du -h "$dmg_path" | cut -f1)"
echo ""

# 执行修复脚本
echo -e "${BLUE}🔧 开始处理DMG...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$SCRIPT_DIR"
./modify-dmg.sh "$dmg_path"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 查找生成的文件
output_file=$(find "$OUTPUT_DIR" -name "*-macsiwen.dmg" -type f | tail -1)

if [ -z "$output_file" ]; then
    echo -e "${RED}❌ 未找到输出文件${NC}"
    exit 1
fi

echo -e "${GREEN}✅ DMG处理完成！${NC}"
echo ""
echo "📊 输出文件信息："
echo "   文件名: $(basename "$output_file")"
echo "   路径: $output_file"
echo "   大小: $(du -h "$output_file" | cut -f1)"
echo ""

# 验收检查清单
echo "================================"
echo -e "${YELLOW}📋 验收检查清单${NC}"
echo "================================"
echo ""
echo "请在Finder中检查以下项目："
echo ""
echo "1. 🖼️  背景图显示"
echo "   ☐ 背景图是否显示为macsiwen品牌图"
echo "   ☐ 背景图是否清晰完整"
echo "   ☐ 没有显示默认白色背景"
echo ""
echo "2. 📐 窗口布局"
echo "   ☐ 图标位置是否正确"
echo "   ☐ 窗口大小是否合适"
echo "   ☐ 文件排列是否整齐"
echo ""
echo "3. 🏷️  卷标名称"
echo "   ☐ 卷标是否为 'macsiwen.com'"
echo "   ☐ Finder标题栏显示正确"
echo ""
echo "4. 📄 文件内容"
echo "   ☐ 应用程序文件存在"
echo "   ☐ Applications快捷方式存在"
echo "   ☐ '访问macsiwen.cc.webloc' 文件存在"
echo ""
echo "================================"
echo ""

# 询问是否打开DMG
echo -e "${BLUE}🚀 准备打开DMG进行验收...${NC}"
echo ""
read -p "是否现在打开DMG？(y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}📂 正在打开DMG...${NC}"
    open "$output_file"
    echo ""
    echo -e "${YELLOW}💡 提示：${NC}"
    echo "   1. 等待DMG挂载完成"
    echo "   2. 检查背景图是否显示"
    echo "   3. 如果背景图不显示，尝试："
    echo "      - 关闭DMG窗口重新打开"
    echo "      - 清除Finder缓存：killall Finder"
    echo "      - 重启Finder"
    echo ""
    echo -e "${BLUE}📝 验收完成后，请反馈结果：${NC}"
    echo "   ✅ 背景图正常显示 → 修复成功"
    echo "   ❌ 背景图仍不显示 → 需要进一步调查"
else
    echo ""
    echo -e "${YELLOW}📂 手动打开命令：${NC}"
    echo "   open \"$output_file\""
fi

echo ""
echo "================================"
echo -e "${GREEN}🎉 验收测试准备完成！${NC}"
echo "================================"
echo ""
echo "📍 输出文件位置："
echo "   $output_file"
echo ""
echo "🔍 如需重新测试："
echo "   $0 \"$dmg_path\""
echo ""