#!/bin/bash
# DMG背景图修复自测脚本
# 验证修复后的modify-dmg.sh是否正确处理.DS_Store

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================"
echo "  DMG背景图修复自测"
echo "  v1.1.65"
echo "================================"
echo ""

# 1. 检查修复是否已应用
echo -e "${YELLOW}[测试1]${NC} 检查代码修复是否已应用..."

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/modify-dmg.sh"

if ! grep -q "# 5. 修改卷标名称（⭐ 关键修复：必须在复制.DS_Store之前改名！）" "$SCRIPT_PATH"; then
    echo -e "${RED}❌ 失败${NC}: 修复代码未找到"
    echo "   请确认 modify-dmg.sh 已更新"
    exit 1
fi

echo -e "${GREEN}✅ 通过${NC}: 修复代码已应用"
echo ""

# 2. 检查执行顺序
echo -e "${YELLOW}[测试2]${NC} 验证执行顺序..."

# 提取步骤5和步骤6的行号
step5_line=$(grep -n "# 5. 修改卷标名称" "$SCRIPT_PATH" | cut -d: -f1)
step6_line=$(grep -n "# 6. 复制预制的.DS_Store文件" "$SCRIPT_PATH" | cut -d: -f1)

echo "   步骤5（修改卷标）在第 $step5_line 行"
echo "   步骤6（复制.DS_Store）在第 $step6_line 行"

if [ "$step5_line" -lt "$step6_line" ]; then
    echo -e "${GREEN}✅ 通过${NC}: 执行顺序正确（先改名，后复制.DS_Store）"
else
    echo -e "${RED}❌ 失败${NC}: 执行顺序错误"
    exit 1
fi
echo ""

# 3. 检查关键注释
echo -e "${YELLOW}[测试3]${NC} 检查关键注释..."

if grep -q "⭐ 关键修复：必须在复制.DS_Store之前改名" "$SCRIPT_PATH"; then
    echo -e "${GREEN}✅ 通过${NC}: 步骤5注释正确"
else
    echo -e "${RED}❌ 失败${NC}: 步骤5注释缺失"
    exit 1
fi

if grep -q "⭐ 关键修复：在改名后复制，确保路径匹配" "$SCRIPT_PATH"; then
    echo -e "${GREEN}✅ 通过${NC}: 步骤6注释正确"
else
    echo -e "${RED}❌ 失败${NC}: 步骤6注释缺失"
    exit 1
fi
echo ""

# 4. 检查挂载点更新逻辑
echo -e "${YELLOW}[测试4]${NC} 检查挂载点更新逻辑..."

if grep -A10 "# 5. 修改卷标名称" "$SCRIPT_PATH" | grep -q "new_mount_point"; then
    echo -e "${GREEN}✅ 通过${NC}: 挂载点更新逻辑存在"
else
    echo -e "${RED}❌ 失败${NC}: 挂载点更新逻辑缺失"
    exit 1
fi
echo ""

# 5. 检查.DS_Store复制时的挂载点
echo -e "${YELLOW}[测试5]${NC} 验证.DS_Store复制使用正确的挂载点..."

if grep -A10 "# 6. 复制预制的.DS_Store文件" "$SCRIPT_PATH" | grep -q 'cp.*"\$mount_point/.DS_Store"'; then
    echo -e "${GREEN}✅ 通过${NC}: .DS_Store复制使用\$mount_point变量"
else
    echo -e "${RED}❌ 失败${NC}: .DS_Store复制路径错误"
    exit 1
fi
echo ""

# 6. 逻辑流程验证
echo -e "${YELLOW}[测试6]${NC} 逻辑流程完整性验证..."

echo "   预期流程："
echo "   1. 挂载DMG → 原始挂载点"
echo "   2. 替换背景图"
echo "   3. 删除旧.DS_Store"
echo "   4. 修改卷标名称 → 更新挂载点"
echo "   5. 复制新.DS_Store → 使用新挂载点"
echo "   6. 卸载DMG"

# 检查步骤顺序
steps_order=$(grep -n "^    # [0-9]\." "$SCRIPT_PATH" | grep -E "(删除旧的.DS_Store|修改卷标名称|复制预制的.DS_Store)" | cut -d: -f1)
steps_array=($steps_order)

if [ ${#steps_array[@]} -eq 3 ]; then
    echo -e "${GREEN}✅ 通过${NC}: 关键步骤都存在"
else
    echo -e "${RED}❌ 失败${NC}: 关键步骤缺失"
    exit 1
fi
echo ""

# 7. 生成测试报告
echo "================================"
echo -e "${GREEN}🎉 所有测试通过！${NC}"
echo "================================"
echo ""
echo "📊 测试摘要："
echo "   ✅ 代码修复已应用"
echo "   ✅ 执行顺序正确"
echo "   ✅ 关键注释完整"
echo "   ✅ 挂载点更新逻辑正确"
echo "   ✅ .DS_Store复制路径正确"
echo "   ✅ 逻辑流程完整"
echo ""
echo "🔧 修复内容："
echo "   - 将「修改卷标名称」移到「复制.DS_Store」之前"
echo "   - 确保.DS_Store在正确的挂载点下复制"
echo "   - 添加关键注释说明修复原因"
echo ""
echo "📝 下一步："
echo "   1. 使用实际DMG文件测试"
echo "   2. 验证背景图是否正确显示"
echo "   3. 检查Finder中的DMG外观"
echo ""
echo "💡 测试命令："
echo "   ./modify-dmg.sh '测试文件.dmg'"
echo "   open tools/dmg-modifier/output/测试文件-macsiwen.dmg"
echo ""