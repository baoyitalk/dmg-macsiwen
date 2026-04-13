#!/bin/bash
# DMG背景图完整单元测试
# 用途：逐步验证每个环节，找出真正问题

# 不使用 set -e，让测试继续执行

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "  DMG背景图完整单元测试"
echo "  v1.1.65"
echo "================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"

# 测试计数
PASS=0
FAIL=0

test_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASS++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAIL++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第1组：模板文件检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 测试1：检查macsiwen-background.png是否存在
echo "[测试1] 检查模板文件 macsiwen-background.png..."
if [ -f "$TEMPLATES_DIR/macsiwen-background.png" ]; then
    size=$(stat -f%z "$TEMPLATES_DIR/macsiwen-background.png" 2>/dev/null)
    time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$TEMPLATES_DIR/macsiwen-background.png" 2>/dev/null)
    test_pass "模板文件存在 (${size}字节, $time)"
else
    test_fail "模板文件不存在: $TEMPLATES_DIR/macsiwen-background.png"
fi
echo ""

# 测试2：检查background.png是否还存在（应该不存在）
echo "[测试2] 检查旧文件 background.png 是否已删除..."
if [ -f "$TEMPLATES_DIR/background.png" ]; then
    test_fail "旧文件仍然存在，可能导致混淆"
else
    test_pass "旧文件已删除"
fi
echo ""

# 测试3：检查.DS_Store文件
echo "[测试3] 检查 .DS_Store 文件..."
if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
    size=$(stat -f%z "$TEMPLATES_DIR/.DS_Store" 2>/dev/null)
    time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$TEMPLATES_DIR/.DS_Store" 2>/dev/null)
    test_pass ".DS_Store存在 (${size}字节, $time)"
    
    # 检查.DS_Store引用的文件名
    test_info "检查.DS_Store中引用的背景图文件名..."
    if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "macsiwen-background.png"; then
        test_pass ".DS_Store引用 macsiwen-background.png"
    else
        test_fail ".DS_Store没有引用 macsiwen-background.png"
        test_info "实际引用的文件："
        strings "$TEMPLATES_DIR/.DS_Store" | grep -i "background" | head -3
    fi
else
    test_fail ".DS_Store不存在"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第2组：脚本代码检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MODIFY_SCRIPT="$SCRIPT_DIR/modify-dmg.sh"

# 测试4：检查脚本中的文件名引用
echo "[测试4] 检查脚本使用的背景图文件名..."
count=$(grep -c "macsiwen-background.png" "$MODIFY_SCRIPT" 2>/dev/null || echo "0")
if [ "$count" -ge 8 ]; then
    test_pass "脚本中有 $count 处引用 macsiwen-background.png"
else
    test_fail "脚本中只有 $count 处引用 macsiwen-background.png（应该>=8）"
fi

# 检查是否还有旧的background.png引用
old_count=$(grep -c "background.png" "$MODIFY_SCRIPT" 2>/dev/null || echo "0")
# 减去注释中的引用
actual_old=$(grep "background.png" "$MODIFY_SCRIPT" | grep -v "^#" | grep -v "macsiwen-background.png" | wc -l | tr -d ' ')
if [ "$actual_old" -eq "0" ]; then
    test_pass "脚本中没有旧的 background.png 引用"
else
    test_fail "脚本中还有 $actual_old 处旧的 background.png 引用"
    echo "   具体位置："
    grep -n "background.png" "$MODIFY_SCRIPT" | grep -v "^#" | grep -v "macsiwen-background.png"
fi
echo ""

# 测试5：检查步骤顺序
echo "[测试5] 检查执行顺序（先改名后复制.DS_Store）..."
step5_line=$(grep -n "# 5. 修改卷标名称" "$MODIFY_SCRIPT" | head -1 | cut -d: -f1)
step6_line=$(grep -n "# 6. 复制预制的.DS_Store文件" "$MODIFY_SCRIPT" | head -1 | cut -d: -f1)

if [ -n "$step5_line" ] && [ -n "$step6_line" ] && [ "$step5_line" -lt "$step6_line" ]; then
    test_pass "执行顺序正确（步骤5在第${step5_line}行，步骤6在第${step6_line}行）"
else
    test_fail "执行顺序错误或步骤未找到"
fi
echo ""

# 测试6：检查挂载点可写性检查
echo "[测试6] 检查挂载点可写性检查代码..."
if grep -q "if \[ ! -w \"\$mount_point\" \]; then" "$MODIFY_SCRIPT"; then
    test_pass "挂载点可写性检查代码存在"
else
    test_fail "挂载点可写性检查代码缺失"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第3组：Finder缓存检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 测试7：检查是否有旧的Finder缓存
echo "[测试7] 检查Finder .DS_Store 缓存..."
if [ -f "$HOME/Library/Preferences/com.apple.finder.plist" ]; then
    test_info "Finder偏好文件存在"
    test_warn "建议：关闭所有DMG后执行 killall Finder 清除缓存"
else
    test_info "Finder偏好文件未找到"
fi
echo ""

# 测试8：检查是否有DMG正在挂载
echo "[测试8] 检查是否有macsiwen.com DMG正在挂载..."
mounted=$(mount | grep "macsiwen.com" || echo "")
if [ -n "$mounted" ]; then
    test_warn "发现已挂载的macsiwen.com DMG："
    echo "$mounted" | while read line; do
        echo "     $line"
    done
    test_warn "建议：卸载所有macsiwen.com DMG后重新测试"
else
    test_pass "没有macsiwen.com DMG正在挂载"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第4组：最近生成的DMG检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

OUTPUT_DIR="$TOOL_DIR/output"

# 测试9：检查最近生成的DMG
echo "[测试9] 检查最近生成的DMG文件..."
if [ -d "$OUTPUT_DIR" ]; then
    latest_dmg=$(ls -t "$OUTPUT_DIR"/*.dmg 2>/dev/null | head -1)
    if [ -n "$latest_dmg" ]; then
        dmg_name=$(basename "$latest_dmg")
        dmg_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$latest_dmg" 2>/dev/null)
        dmg_size=$(du -h "$latest_dmg" | cut -f1)
        
        test_info "最新DMG: $dmg_name"
        test_info "生成时间: $dmg_time"
        test_info "文件大小: $dmg_size"
        
        # 检查生成时间是否在最近30分钟内
        now=$(date +%s)
        dmg_timestamp=$(stat -f %m "$latest_dmg" 2>/dev/null)
        age=$((now - dmg_timestamp))
        
        if [ $age -lt 1800 ]; then
            test_pass "DMG是最近30分钟内生成的（${age}秒前）"
        else
            minutes=$((age / 60))
            test_warn "DMG是 $minutes 分钟前生成的，可能不是最新修复的版本"
        fi
    else
        test_warn "output目录中没有DMG文件"
    fi
else
    test_fail "output目录不存在"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试总结"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "通过: $PASS"
echo "失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    echo ""
    echo "建议操作："
    echo "1. 关闭所有已打开的macsiwen.com DMG"
    echo "2. 执行：killall Finder（清除Finder缓存）"
    echo "3. 使用Electron重新生成DMG"
    echo "4. 打开新生成的DMG验证"
else
    echo -e "${RED}❌ 有 $FAIL 个测试失败！${NC}"
    echo ""
    echo "请根据上述失败的测试项进行修复。"
fi
echo ""