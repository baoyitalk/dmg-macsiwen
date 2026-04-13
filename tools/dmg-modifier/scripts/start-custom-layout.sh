#!/bin/bash
# 一键启动自定义布局流程

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════╗
║   macsiwen DMG 自定义布局工具        ║
║   Custom Layout Designer             ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}📋 流程说明：${NC}"
echo ""
echo "1️⃣  创建可编辑的模板DMG"
echo "2️⃣  在Finder中自定义布局"
echo "3️⃣  提取.DS_Store文件"
echo "4️⃣  测试自定义布局"
echo ""
echo -e "${YELLOW}按Enter键开始，或Ctrl+C取消${NC}"
read

# 步骤1：创建模板DMG
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 1/4: 创建模板DMG${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
"$SCRIPT_DIR/create-template-dmg.sh"

# 等待用户调整布局
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 2/4: 调整布局${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 请在Finder中完成以下操作：${NC}"
echo ""
echo "✓ 右键空白处 → 显示视图选项"
echo "✓ 设置图标大小、网格间距"
echo "✓ 设置背景图（拖拽 .background/background.png）"
echo "✓ 调整窗口大小（建议1200×800）"
echo "✓ 拖拽摆放各个元素"
echo ""
echo -e "${YELLOW}完成后按Enter继续...${NC}"
read

# 显示隐藏文件
echo ""
echo -e "${GREEN}显示隐藏文件...${NC}"
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder
sleep 2

echo ""
echo -e "${YELLOW}请确认.DS_Store文件已生成${NC}"
echo -e "${YELLOW}在Finder中查看 /Volumes/macsiwen.com/.DS_Store${NC}"
echo ""
echo -e "${YELLOW}确认后按Enter继续...${NC}"
read

# 步骤3：提取.DS_Store
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 3/4: 提取.DS_Store${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
"$SCRIPT_DIR/extract-ds-store.sh"

# 清理
echo ""
echo -e "${GREEN}清理临时文件...${NC}"
hdiutil detach /Volumes/macsiwen.com 2>/dev/null || true
echo ""
echo -e "${YELLOW}是否删除桌面上的模板DMG？(y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    rm ~/Desktop/macsiwen-template.dmg
    echo -e "${GREEN}✅ 已删除${NC}"
fi

# 恢复隐藏文件设置
echo ""
echo -e "${GREEN}恢复Finder设置...${NC}"
defaults write com.apple.finder AppleShowAllFiles -bool false
killall Finder

# 步骤4：测试
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 4/4: 测试自定义布局${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}是否立即测试自定义布局？(y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}请将测试DMG文件拖到终端窗口，然后按Enter${NC}"
    read -r test_dmg
    
    if [ -f "$test_dmg" ]; then
        echo ""
        echo -e "${GREEN}开始处理...${NC}"
        "$SCRIPT_DIR/modify-dmg.sh" "$test_dmg"
        
        echo ""
        echo -e "${GREEN}✅ 处理完成！${NC}"
        echo -e "${YELLOW}输出位置：$(dirname "$SCRIPT_DIR")/output/${NC}"
        echo ""
        echo -e "${YELLOW}是否打开输出目录？(y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            open "$(dirname "$SCRIPT_DIR")/output"
        fi
    else
        echo -e "${YELLOW}文件不存在，跳过测试${NC}"
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 全部完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📚 后续操作：${NC}"
echo ""
echo "• 批量处理DMG："
echo "  ./modify-dmg.sh --batch ~/Downloads/dmg-files"
echo ""
echo "• Web界面处理："
echo "  访问 http://localhost:3002/shop/admin/dmg-editor"
echo ""
echo "• 查看详细文档："
echo "  cat ../CUSTOM_LAYOUT_GUIDE.md"
echo ""
