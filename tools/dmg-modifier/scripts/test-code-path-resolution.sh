#!/bin/bash

# ========================================
# v1.1.64 代码路径解析测试
# 目的：发现Bug 4类型的路径解析问题
# 测试支柱红线：测试必须能发现Bug
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔍 v1.1.64 代码路径解析测试${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}[INFO]${NC} 测试目标: 检测代码中的硬编码路径"
echo -e "${BLUE}[INFO]${NC} 测试日期: $(date)"
echo ""

# 测试计数器
total_tests=0
failed_tests=0

# 测试函数
test_case() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    total_tests=$((total_tests + 1))
    
    if eval "$test_command"; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}[✓]${NC} $test_name"
            return 0
        else
            echo -e "${RED}[✗]${NC} $test_name"
            echo -e "${RED}   预期失败，但实际通过${NC}"
            failed_tests=$((failed_tests + 1))
            return 1
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}[✓]${NC} $test_name (预期失败)"
            return 0
        else
            echo -e "${RED}[✗]${NC} $test_name"
            failed_tests=$((failed_tests + 1))
            return 1
        fi
    fi
}

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}测试组1: electron/dmg-main.js 路径解析检测${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DMG_MAIN="$PROJECT_ROOT/electron/dmg-main.js"

# TC-CR-001: 检测硬编码的templates路径（不在条件判断中）
TEMPLATES_HARDCODED=$(grep -n "templatesDir = path.join(__dirname, '../tools" "$DMG_MAIN" | wc -l | tr -d ' ')
test_case "TC-CR-001: templates路径不硬编码（使用getTemplatesDir）" \
    "[ \"$TEMPLATES_HARDCODED\" -eq 0 ]" \
    "pass"

# TC-CR-002: 必须使用 getTemplatesDir() 或条件判断
test_case "TC-CR-002: templates路径使用统一函数或条件判断" \
    "grep -q 'getTemplatesDir()' \"$DMG_MAIN\" || grep -q 'if (app.isPackaged)' \"$DMG_MAIN\"" \
    "pass"

# TC-CR-003: upload-background handler 使用正确路径
test_case "TC-CR-003: upload-background 使用 getTemplatesDir()" \
    "grep -A5 \"handle('upload-background'\" \"$DMG_MAIN\" | grep -q 'getTemplatesDir()'" \
    "pass"

# TC-CR-004: start-ds-store-creation handler 使用正确路径
test_case "TC-CR-004: start-ds-store-creation 使用 getTemplatesDir()" \
    "grep -A5 \"handle('start-ds-store-creation'\" \"$DMG_MAIN\" | grep -q 'getTemplatesDir()'" \
    "pass"

# TC-CR-005: finish-ds-store-creation handler 使用正确路径
test_case "TC-CR-005: finish-ds-store-creation 使用 getTemplatesDir()" \
    "grep -A5 \"handle('finish-ds-store-creation'\" \"$DMG_MAIN\" | grep -q 'getTemplatesDir()'" \
    "pass"

# TC-CR-006: reset-background handler 使用正确路径
test_case "TC-CR-006: reset-background 使用 getTemplatesDir()" \
    "grep -A5 \"handle('reset-background'\" \"$DMG_MAIN\" | grep -q 'getTemplatesDir()'" \
    "pass"

# TC-CR-007: save-website-settings handler 使用正确路径
test_case "TC-CR-007: save-website-settings 使用 getTemplatesDir()" \
    "grep -A5 \"handle('save-website-settings'\" \"$DMG_MAIN\" | grep -q 'getTemplatesDir()'" \
    "pass"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}测试组2: 通用路径解析模式检测${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TC-CR-008: 检测tempDmgPath是否使用getTempDmgPath()
TEMP_HARDCODED=$(grep -n "tempDmgPath = path.join(__dirname" "$DMG_MAIN" | wc -l | tr -d ' ')
test_case "TC-CR-008: tempDmgPath使用getTempDmgPath()函数" \
    "[ \"$TEMP_HARDCODED\" -eq 0 ]" \
    "pass"

# TC-CR-009: 必须有 getTemplatesDir 函数定义
test_case "TC-CR-009: 存在 getTemplatesDir() 函数定义" \
    "grep -q 'function getTemplatesDir()' \"$DMG_MAIN\"" \
    "pass"

# TC-CR-010: getTemplatesDir 函数实现正确
test_case "TC-CR-010: getTemplatesDir() 包含 app.isPackaged 判断" \
    "grep -A5 'function getTemplatesDir()' \"$DMG_MAIN\" | grep -q 'app.isPackaged'" \
    "pass"

# TC-CR-011: getTemplatesDir 使用 process.resourcesPath
test_case "TC-CR-011: getTemplatesDir() 使用 process.resourcesPath" \
    "grep -A5 'function getTemplatesDir()' \"$DMG_MAIN\" | grep -q 'process.resourcesPath'" \
    "pass"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}测试组3: 脚本路径解析检测（bash）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TC-CR-012: process-dmg handler 使用条件判断
test_case "TC-CR-012: process-dmg 使用 app.isPackaged 判断" \
    "grep -A10 \"handle('process-dmg'\" \"$DMG_MAIN\" | grep -q 'app.isPackaged'" \
    "pass"

# TC-CR-013: processSingleDmgFile 函数使用条件判断
test_case "TC-CR-013: processSingleDmgFile 使用 app.isPackaged 判断" \
    "grep -A10 'function processSingleDmgFile' \"$DMG_MAIN\" | grep -q 'app.isPackaged'" \
    "pass"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}测试统计${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "总测试数: $total_tests"
echo "通过数: $((total_tests - failed_tests))"
echo "失败数: $failed_tests"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}✅ 所有代码路径解析测试通过！${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 代码路径解析测试失败！${NC}"
    echo ""
    echo -e "${YELLOW}[!]${NC} 发现硬编码路径或路径解析Bug"
    echo -e "${YELLOW}[!]${NC} 请修复后重新测试"
    echo ""
    exit 1
fi