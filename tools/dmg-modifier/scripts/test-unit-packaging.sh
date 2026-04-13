#!/bin/bash

# v1.1.64 单元测试 - 打包环境路径解析
# 测试目标：验证打包后的路径解析逻辑
# 测试用例：TC-U-001 至 TC-U-010

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果数组
declare -a TEST_RESULTS

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 测试断言函数
test_assert() {
    local description=$1
    local condition=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$condition"; then
        log_success "TC-U-$(printf "%03d" $TOTAL_TESTS): $description"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✓ $description")
        return 0
    else
        log_error "TC-U-$(printf "%03d" $TOTAL_TESTS): $description"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("✗ $description")
        return 1
    fi
}

# 打印测试头部
print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 打印测试摘要
print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📊 单元测试总结${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "总测试数: $TOTAL_TESTS"
    echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}✅ 所有单元测试通过！${NC}"
    else
        echo -e "\n${RED}❌ 部分测试失败${NC}"
        echo ""
        echo "失败的测试："
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $result == ✗* ]]; then
                echo -e "${RED}$result${NC}"
            fi
        done
    fi
    echo ""
}

# 主测试函数
main() {
    print_header "🧪 v1.1.64 单元测试 - 打包环境路径解析"
    
    log_info "测试环境: $(uname -s)"
    log_info "测试日期: $(date)"
    
    # 检测是否在打包环境（优先检测dist目录）
    if [ -d "dist/mac/DMG品牌化工具.app" ]; then
        log_info "检测到本地打包输出（x64）"
        APP_PATH="dist/mac/DMG品牌化工具.app"
    elif [ -d "dist/mac-arm64/DMG品牌化工具.app" ]; then
        log_info "检测到本地打包输出（arm64）"
        APP_PATH="dist/mac-arm64/DMG品牌化工具.app"
    elif [ -d "/Applications/DMG品牌化工具.app" ]; then
        log_info "检测到已安装的应用"
        APP_PATH="/Applications/DMG品牌化工具.app"
    else
        log_warning "未检测到打包应用，将测试配置文件"
        APP_PATH=""
    fi
    
    # ========================================
    # 测试组1: 配置验证（TC-U-005）
    # ========================================
    print_header "测试组1: electron-builder配置验证"
    
    # 检查electron-builder.json是否存在
    test_assert "electron-builder.json 文件存在" "[ -f 'electron-builder.json' ]"
    
    if [ -f "electron-builder.json" ]; then
        # 检查extraResources配置
        if grep -q "extraResources" electron-builder.json; then
            test_assert "配置包含 extraResources" "true"
            
            # 检查tools目录是否配置
            if grep -q "tools/dmg-modifier" electron-builder.json; then
                test_assert "extraResources 包含 tools/dmg-modifier" "true"
            else
                test_assert "extraResources 包含 tools/dmg-modifier" "false"
            fi
        else
            test_assert "配置包含 extraResources" "false"
            log_warning "建议添加 extraResources 配置"
        fi
        
        # 检查files配置
        if grep -q '"files"' electron-builder.json; then
            test_assert "配置包含 files 字段" "true"
        else
            test_assert "配置包含 files 字段" "false"
        fi
    fi
    
    # ========================================
    # 测试组2: 打包后目录结构验证
    # ========================================
    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
        print_header "测试组2: 打包后目录结构验证"
        
        RESOURCES_PATH="$APP_PATH/Contents/Resources"
        
        # 检查Resources目录
        test_assert "Resources 目录存在" "[ -d '$RESOURCES_PATH' ]"
        
        # 检查app.asar文件
        test_assert "app.asar 文件存在" "[ -f '$RESOURCES_PATH/app.asar' ]"
        
        # 检查tools目录（extraResources）
        if [ -d "$RESOURCES_PATH/tools" ]; then
            test_assert "tools 目录在 Resources 下（extraResources）" "true"
            
            # 检查bash脚本
            test_assert "modify-dmg.sh 存在" "[ -f '$RESOURCES_PATH/tools/dmg-modifier/scripts/modify-dmg.sh' ]"
            test_assert "recreate-ds-store.sh 存在" "[ -f '$RESOURCES_PATH/tools/dmg-modifier/scripts/recreate-ds-store.sh' ]"
            
            # 检查模板文件
            test_assert ".DS_Store 模板存在" "[ -f '$RESOURCES_PATH/tools/dmg-modifier/templates/.DS_Store' ]"
            test_assert "background.png 存在" "[ -f '$RESOURCES_PATH/tools/dmg-modifier/templates/background.png' ]"
            
            # 检查bash脚本可执行权限
            if [ -f "$RESOURCES_PATH/tools/dmg-modifier/scripts/modify-dmg.sh" ]; then
                test_assert "modify-dmg.sh 可执行" "[ -x '$RESOURCES_PATH/tools/dmg-modifier/scripts/modify-dmg.sh' ]"
            fi
        else
            test_assert "tools 目录在 Resources 下（extraResources）" "false"
            log_warning "tools目录不在extraResources中，可能在app.asar内"
            
            # 检查app.asar.unpacked
            if [ -d "$RESOURCES_PATH/app.asar.unpacked" ]; then
                test_assert "app.asar.unpacked 目录存在" "true"
                
                if [ -d "$RESOURCES_PATH/app.asar.unpacked/tools" ]; then
                    test_assert "tools 在 app.asar.unpacked 中" "true"
                else
                    test_assert "tools 在 app.asar.unpacked 中" "false"
                fi
            fi
        fi
    else
        log_warning "跳过打包后目录结构测试（未找到打包应用）"
    fi
    
    # ========================================
    # 测试组3: 路径解析逻辑验证
    # ========================================
    print_header "测试组3: 路径解析逻辑验证"
    
    # 检查项目结构
    test_assert "项目根目录存在 tools/dmg-modifier" "[ -d 'tools/dmg-modifier' ]"
    test_assert "开发环境脚本存在" "[ -f 'tools/dmg-modifier/scripts/modify-dmg.sh' ]"
    test_assert "开发环境模板存在" "[ -f 'tools/dmg-modifier/templates/.DS_Store' ]"
    
    # 检查临时目录（开发环境）
    if [ -d "tools/dmg-modifier/temp" ]; then
        test_assert "开发环境临时目录存在" "true"
    else
        test_assert "开发环境临时目录可创建" "mkdir -p 'tools/dmg-modifier/temp' 2>/dev/null"
    fi
    
    # 检查系统临时目录
    SYSTEM_TEMP=$(mktemp -d 2>/dev/null || echo "/tmp")
    test_assert "系统临时目录可用" "[ -d '$SYSTEM_TEMP' ]"
    test_assert "系统临时目录可写" "[ -w '$SYSTEM_TEMP' ]"
    
    # 清理测试临时目录
    if [[ "$SYSTEM_TEMP" == *"tmp."* ]]; then
        rm -rf "$SYSTEM_TEMP" 2>/dev/null || true
    fi
    
    # ========================================
    # 测试组4: 文件权限和可读性
    # ========================================
    print_header "测试组4: 文件权限和可读性"
    
    # 检查bash脚本权限（开发环境）
    if [ -f "tools/dmg-modifier/scripts/modify-dmg.sh" ]; then
        test_assert "modify-dmg.sh 可执行（开发）" "[ -x 'tools/dmg-modifier/scripts/modify-dmg.sh' ]"
    fi
    
    if [ -f "tools/dmg-modifier/scripts/recreate-ds-store.sh" ]; then
        test_assert "recreate-ds-store.sh 可执行（开发）" "[ -x 'tools/dmg-modifier/scripts/recreate-ds-store.sh' ]"
    fi
    
    # 检查模板文件可读
    if [ -f "tools/dmg-modifier/templates/.DS_Store" ]; then
        test_assert ".DS_Store 模板可读（开发）" "[ -r 'tools/dmg-modifier/templates/.DS_Store' ]"
        
        # 检查文件大小
        DS_STORE_SIZE=$(stat -f%z "tools/dmg-modifier/templates/.DS_Store" 2>/dev/null || stat -c%s "tools/dmg-modifier/templates/.DS_Store" 2>/dev/null || echo "0")
        test_assert ".DS_Store 模板大小正常 (>1KB)" "[ $DS_STORE_SIZE -gt 1000 ]"
    fi
    
    if [ -f "tools/dmg-modifier/templates/background.png" ]; then
        test_assert "background.png 可读（开发）" "[ -r 'tools/dmg-modifier/templates/background.png' ]"
        
        # 检查PNG格式
        if command -v file >/dev/null 2>&1; then
            PNG_TYPE=$(file "tools/dmg-modifier/templates/background.png")
            if echo "$PNG_TYPE" | grep -q "PNG"; then
                test_assert "background.png 是有效的PNG格式" "true"
            else
                test_assert "background.png 是有效的PNG格式" "false"
            fi
        fi
    fi
    
    # 打印测试摘要
    print_summary
    
    # 返回退出码
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 执行主函数
main "$@"