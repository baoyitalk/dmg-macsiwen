#!/bin/bash
# DMG背景图修复验收脚本
# 用途：一键清理环境，准备验收

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "  DMG背景图修复验收脚本"
echo "  v1.1.65"
echo "================================"
echo ""

# 步骤1：卸载所有旧DMG
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤1: 卸载所有旧DMG${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 统计要卸载的DMG数量
dmg_count=$(mount | grep -c "macsiwen.com" || echo "0")

if [ "$dmg_count" -eq "0" ]; then
    echo -e "${GREEN}✅ 没有已挂载的macsiwen.com DMG${NC}"
else
    echo -e "${YELLOW}发现 $dmg_count 个已挂载的macsiwen.com DMG，开始卸载...${NC}"
    echo ""
    
    # 卸载所有macsiwen.com DMG
    mount | grep "macsiwen.com" | awk '{print $1}' | while read disk; do
        echo "  卸载 $disk..."
        hdiutil detach "$disk" -force 2>/dev/null || true
    done
    
    sleep 2
    
    # 验证是否全部卸载
    remaining=$(mount | grep -c "macsiwen.com" || echo "0")
    if [ "$remaining" -eq "0" ]; then
        echo ""
        echo -e "${GREEN}✅ 所有旧DMG已卸载${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  还有 $remaining 个DMG未能卸载，请手动卸载${NC}"
    fi
fi

echo ""

# 步骤2：清除Finder缓存
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤2: 清除Finder缓存${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "重启Finder..."
killall Finder 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Finder已重启${NC}"
echo ""

# 步骤3：验收指南
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤3: 验收指南${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "环境已清理完成！现在请按以下步骤验收："
echo ""
echo -e "${GREEN}1. 启动Electron应用${NC}"
echo "   cd $(dirname $(dirname $(dirname "$0")))"
echo "   npm run electron:dev"
echo ""
echo -e "${GREEN}2. 在Electron中处理DMG${NC}"
echo "   - 选择测试DMG文件"
echo "   - 点击开始处理"
echo "   - 等待处理完成"
echo ""
echo -e "${GREEN}3. 打开生成的DMG验证${NC}"
echo "   - 文件在 tools/dmg-modifier/output/"
echo "   - 查找最新的 *-macsiwen.dmg 文件"
echo "   - 双击打开"
echo ""
echo -e "${GREEN}4. 验收检查清单${NC}"
echo "   ☐ 背景图是否显示macsiwen品牌图？"
echo "   ☐ 不是默认白色/浅蓝色背景？"
echo "   ☐ 卷标名称是 'macsiwen.com'？"
echo "   ☐ 图标布局正常？"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 验收准备完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 提示：${NC}"
echo "   如果背景图仍然不显示："
echo "   1. 检查DMG生成时间是否是最新的"
echo "   2. 重新关闭DMG并重新打开"
echo "   3. 再次执行 killall Finder"
echo ""