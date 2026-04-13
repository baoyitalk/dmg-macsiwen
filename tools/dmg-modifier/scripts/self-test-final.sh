#!/bin/bash
# DMG背景图修复最终自测脚本
# v1.1.65

# 不使用 set -e，让所有测试都能执行

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"
OUTPUT_DIR="$TOOL_DIR/output"

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

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

echo "================================"
echo "  DMG背景图修复最终自测"
echo "  v1.1.65"
echo "================================"
echo ""

# 第1组：.DS_Store模板验证（⭐ 关键）
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}第1组: .DS_Store模板路径验证${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "[测试1] 检查.DS_Store是否引用Desktop路径..."
if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "/Desktop/"; then
    test_fail ".DS_Store引用了Desktop路径（错误的绝对路径）"
    test_info "发现的Desktop路径："
    strings "$TEMPLATES_DIR/.DS_Store" | grep "/Desktop/" | head -3
else
    test_pass ".DS_Store没有引用Desktop路径"
fi
echo ""

echo "[测试2] 检查.DS_Store是否引用正确的相对路径..."
if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "\.DropDMGBackground"; then
    test_pass ".DS_Store引用了.DropDMGBackground目录"
elif strings "$TEMPLATES_DIR/.DS_Store" | grep -q "\.background"; then
    test_pass ".DS_Store引用了.background目录"
else
    test_fail ".DS_Store没有引用背景图目录"
fi
echo ""

echo "[测试3] 检查.DS_Store更新时间..."
ds_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$TEMPLATES_DIR/.DS_Store" 2>/dev/null || echo "未知")
ds_timestamp=$(stat -f %m "$TEMPLATES_DIR/.DS_Store" 2>/dev/null || echo "0")
now=$(date +%s)
age=$((now - ds_timestamp))

test_info ".DS_Store更新时间: $ds_time"

if [ $age -lt 3600 ]; then
    # 1小时内更新
    test_pass ".DS_Store是最近1小时内更新的（${age}秒前）"
else
    minutes=$((age / 60))
    if [ $minutes -lt 60 ]; then
        test_info ".DS_Store是 ${minutes} 分钟前更新的"
    else
        hours=$((minutes / 60))
        test_info ".DS_Store是 ${hours} 小时前更新的"
    fi
fi
echo ""

# 第2组：背景图文件验证
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}第2组: 背景图模板文件验证${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "[测试4] 检查macsiwen-background.png..."
if [ -f "$TEMPLATES_DIR/macsiwen-background.png" ]; then
    size=$(stat -f%z "$TEMPLATES_DIR/macsiwen-background.png" 2>/dev/null)
    test_pass "背景图文件存在 (${size}字节)"
else
    test_fail "背景图文件不存在"
fi
echo ""

echo "[测试5] 检查.DS_Store引用的文件名..."
if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "macsiwen-background.png"; then
    test_pass ".DS_Store引用 macsiwen-background.png"
else
    test_fail ".DS_Store没有引用 macsiwen-background.png"
    test_info ".DS_Store中的background引用："
    strings "$TEMPLATES_DIR/.DS_Store" | grep -i "background" | head -3
fi
echo ""

# 第3组：脚本代码验证
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}第3组: 脚本代码验证${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "[测试6] 检查脚本文件名引用..."
count=$(grep -c "macsiwen-background.png" "$SCRIPT_DIR/modify-dmg.sh" 2>/dev/null || echo "0")
if [ "$count" -ge "10" ]; then
    test_pass "脚本中有 $count 处引用 macsiwen-background.png"
else
    test_fail "脚本中只有 $count 处引用 macsiwen-background.png（应该>=10）"
fi
echo ""

echo "[测试7] 检查步骤执行顺序..."
step5_line=$(grep -n "# 5. 修改卷标名称" "$SCRIPT_DIR/modify-dmg.sh" | head -1 | cut -d: -f1)
step6_line=$(grep -n "# 6. 复制预制的.DS_Store文件" "$SCRIPT_DIR/modify-dmg.sh" | head -1 | cut -d: -f1)

if [ -n "$step5_line" ] && [ -n "$step6_line" ] && [ "$step5_line" -lt "$step6_line" ]; then
    test_pass "执行顺序正确（先改卷标，后复制.DS_Store）"
else
    test_fail "执行顺序错误"
fi
echo ""

# 第4组：生成测试DMG并验证
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}第4组: 生成测试DMG并验证内部结构${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否有最近生成的DMG
echo "[测试8] 检查output目录中的DMG..."
if [ -d "$OUTPUT_DIR" ]; then
    latest_dmg=$(ls -t "$OUTPUT_DIR"/*.dmg 2>/dev/null | head -1)
    if [ -n "$latest_dmg" ]; then
        dmg_name=$(basename "$latest_dmg")
        dmg_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$latest_dmg" 2>/dev/null)
        dmg_timestamp=$(stat -f %m "$latest_dmg" 2>/dev/null)
        dmg_age=$((now - dmg_timestamp))
        
        test_info "最新DMG: $dmg_name"
        test_info "生成时间: $dmg_time"
        
        if [ $dmg_age -lt 600 ]; then
            # 10分钟内
            test_pass "DMG是最近10分钟内生成的（${dmg_age}秒前）"
            
            # 挂载并验证内部结构
            echo ""
            echo "[测试9] 验证DMG内部结构..."
            test_info "挂载DMG进行验证..."
            
            attach_output=$(hdiutil attach "$latest_dmg" -readonly -nobrowse 2>&1)
            mount_point=$(echo "$attach_output" | grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/')
            
            if [ -n "$mount_point" ]; then
                test_pass "DMG已挂载: $mount_point"
                
                # 检查.DropDMGBackground目录
                if [ -d "$mount_point/.DropDMGBackground" ]; then
                    test_pass ".DropDMGBackground目录存在"
                    
                    # 检查背景图文件
                    if [ -f "$mount_point/.DropDMGBackground/macsiwen-background.png" ]; then
                        bg_size=$(stat -f%z "$mount_point/.DropDMGBackground/macsiwen-background.png" 2>/dev/null)
                        test_pass "背景图文件存在 (${bg_size}字节)"
                    else
                        test_fail "背景图文件不存在"
                        test_info "目录内容："
                        ls -la "$mount_point/.DropDMGBackground/" 2>&1 || true
                    fi
                else
                    test_fail ".DropDMGBackground目录不存在"
                fi
                
                # 检查.DS_Store
                if [ -f "$mount_point/.DS_Store" ]; then
                    test_pass ".DS_Store文件存在"
                    
                    # 验证.DS_Store中的路径
                    if strings "$mount_point/.DS_Store" | grep -q "/Desktop/"; then
                        test_fail ".DS_Store中还有Desktop路径（错误！）"
                    else
                        test_pass ".DS_Store没有Desktop路径"
                    fi
                else
                    test_fail ".DS_Store文件不存在"
                fi
                
                # 卸载DMG
                hdiutil detach "$(echo "$attach_output" | grep "/dev/" | awk '{print $1}')" -force 2>/dev/null || true
            else
                test_fail "无法挂载DMG"
            fi
        else
            minutes=$((dmg_age / 60))
            test_info "DMG是 $minutes 分钟前生成的"
            test_info "建议重新生成一个最新的DMG来测试"
        fi
    else
        test_info "output目录中没有DMG文件"
        test_info "需要先生成一个测试DMG"
    fi
else
    test_info "output目录不存在"
fi

echo ""

# 测试总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}测试总结${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "通过: $PASS"
echo "失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    echo ""
    echo "修复已完成！可以正式使用了。"
    echo ""
    echo "使用方法："
    echo "  1. npm run electron:dev"
    echo "  2. 选择DMG文件处理"
    echo "  3. 打开生成的DMG验证背景图"
else
    echo -e "${RED}❌ 有 $FAIL 个测试失败${NC}"
    echo ""
    echo "需要修复的问题："
    echo ""
    if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "/Desktop/"; then
        echo "  ⚠️  .DS_Store模板文件引用了Desktop路径"
        echo "     需要重新制作.DS_Store模板"
        echo "     参考：DS_STORE_FIX_GUIDE.md"
    fi
fi
echo ""