#!/bin/bash

# v1.1.64 E2E测试 - 打包环境完整流程
# 测试目标：验证打包后的完整业务流程
# 测试用例：TC-E-001 至 TC-E-006, TC-S-001

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_manual() {
    echo -e "${YELLOW}[手动]${NC} $1"
}

# 打印测试头部
print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 打印分隔线
print_separator() {
    echo ""
    echo "────────────────────────────────────────────────────"
    echo ""
}

# 等待用户确认
wait_for_confirmation() {
    local message=$1
    echo ""
    echo -e "${YELLOW}$message${NC}"
    read -p "按回车键继续... " -r
    echo ""
}

# 检查应用是否安装
check_app_installation() {
    print_header "检查应用安装"
    
    if [ -d "/Applications/DMG品牌化工具.app" ]; then
        log_success "应用已安装: /Applications/DMG品牌化工具.app"
        APP_PATH="/Applications/DMG品牌化工具.app"
        return 0
    elif [ -d "dist/mac-arm64/DMG品牌化工具.app" ]; then
        log_success "找到本地打包输出"
        APP_PATH="dist/mac-arm64/DMG品牌化工具.app"
        
        log_warning "建议先安装应用进行完整测试"
        read -p "是否使用本地版本测试？(y/n) " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            log_error "取消测试"
            return 1
        fi
    else
        log_error "未找到打包应用"
        echo ""
        echo "请先执行以下步骤之一："
        echo "1. 打包应用: npm run build:electron"
        echo "2. 安装应用到/Applications目录"
        return 1
    fi
}

# TC-E-001: 开发环境完整流程
test_dev_flow() {
    print_header "TC-E-001: 开发环境完整流程验证"
    
    log_info "此测试需要在开发环境执行"
    log_info "目标：验证开发环境功能正常（作为对照）"
    
    print_separator
    
    # 检查开发环境文件
    log_step "1. 检查开发环境文件"
    
    local checks_passed=true
    
    if [ -f "tools/dmg-modifier/scripts/modify-dmg.sh" ]; then
        log_success "modify-dmg.sh 存在"
    else
        log_error "modify-dmg.sh 不存在"
        checks_passed=false
    fi
    
    if [ -f "tools/dmg-modifier/templates/.DS_Store" ]; then
        log_success ".DS_Store 模板存在"
    else
        log_error ".DS_Store 模板不存在"
        checks_passed=false
    fi
    
    if [ -f "electron/dmg-main.js" ]; then
        log_success "Electron主进程存在"
    else
        log_error "Electron主进程不存在"
        checks_passed=false
    fi
    
    if [ "$checks_passed" = true ]; then
        log_success "开发环境文件检查通过"
    else
        log_error "开发环境文件检查失败"
    fi
    
    print_separator
    log_info "开发环境验证完成"
    log_warning "注意：此测试作为打包环境的对照基准"
}

# TC-E-002: 打包环境完整流程 ⭐ 核心测试
test_packaged_flow() {
    print_header "TC-E-002: 打包环境完整流程 ⭐ 核心测试"
    
    log_warning "这是v1.1.64的核心验收测试"
    log_info "目标：验证打包后预制模板功能正常"
    
    print_separator
    
    # 步骤1: 启动应用
    log_step "步骤1: 启动打包后的应用"
    echo "命令: open \"$APP_PATH\""
    log_manual "请手动执行: open \"$APP_PATH\""
    wait_for_confirmation "应用已启动？"
    
    # 步骤2: 切换到设置页面
    log_step "步骤2: 切换到'设置'页面"
    log_manual "在应用中点击'⚙️ 设置'标签页"
    wait_for_confirmation "已切换到设置页面？"
    
    # 步骤3: 制作.DS_Store模板
    log_step "步骤3: 制作.DS_Store模板"
    log_manual "点击'🛠️ 制作.DS_Store模板'按钮"
    echo ""
    echo "预期行为："
    echo "  - 弹出成功提示"
    echo "  - Finder会打开一个DMG"
    echo "  - 可以调整布局"
    echo ""
    wait_for_confirmation "按钮点击后有反应？（如果'没反应'说明bug未修复）"
    
    # 步骤4: 调整DMG布局
    log_step "步骤4: 在Finder中调整DMG布局"
    echo ""
    echo "在打开的DMG窗口中："
    echo "  1. 设置背景图（如果有）"
    echo "  2. 调整图标位置"
    echo "  3. 调整窗口大小"
    echo "  4. 关闭Finder窗口"
    echo ""
    wait_for_confirmation "已完成布局调整并关闭窗口？"
    
    # 步骤5: 完成模板制作
    log_step "步骤5: 完成模板制作"
    log_manual "在应用中点击'完成'按钮"
    wait_for_confirmation "看到'模板制作成功'提示？"
    
    # 步骤6: 切换到批量处理
    log_step "步骤6: 切换到'批量处理'页面"
    log_manual "点击'📦 批量处理'标签页"
    wait_for_confirmation "已切换到批量处理页面？"
    
    # 步骤7: 选择DMG文件
    log_step "步骤7: 选择要处理的DMG文件"
    log_manual "点击'选择DMG文件'按钮，选择1-3个测试DMG"
    wait_for_confirmation "已选择DMG文件？"
    
    # 步骤8: 选择输出目录
    log_step "步骤8: 选择输出目录"
    log_manual "点击'选择输出目录'按钮"
    wait_for_confirmation "已选择输出目录？"
    
    # 步骤9: 开始处理
    log_step "步骤9: 开始批量处理"
    log_manual "点击'开始处理'按钮"
    wait_for_confirmation "处理已完成？"
    
    # 步骤10: 验证结果 ⭐ 核心验收点
    log_step "步骤10: 验证处理结果 ⭐ 核心验收点"
    echo ""
    echo -e "${BOLD}${RED}关键验证：${NC}"
    echo ""
    echo "打开输出的DMG文件，检查："
    echo ""
    echo "  1. 背景图是否正确显示？"
    echo "  2. 图标位置是否符合预制布局？"
    echo "  3. 窗口大小是否正确？"
    echo ""
    echo -e "${YELLOW}这是v1.1.64的核心验收标准！${NC}"
    echo ""
    
    read -p "预制模板是否生效？(y/n) " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_success "✅ TC-E-002通过：打包后预制模板功能正常"
        log_success "✅ v1.1.64核心Bug已修复！"
        return 0
    else
        log_error "❌ TC-E-002失败：预制模板未生效"
        log_error "❌ v1.1.64核心Bug仍未修复"
        
        echo ""
        echo "请检查："
        echo "  1. CDP日志: query_electron_prod_logs()"
        echo "  2. 临时文件路径是否正确"
        echo "  3. 模板文件是否被打包"
        echo "  4. bash脚本是否找到模板"
        echo ""
        
        return 1
    fi
}

# TC-E-003: UI元素验证
test_ui_elements() {
    print_header "TC-E-003: UI元素验证"
    
    log_info "验证UI改动是否正确"
    
    print_separator
    
    log_step "1. 检查设置页面UI"
    echo ""
    echo "在'设置'页面检查："
    echo ""
    echo "应该删除的元素："
    echo "  ❌ '上传背景图'按钮"
    echo "  ❌ '恢复默认'按钮"
    echo "  ❌ '布局模板（即将推出）'占位符"
    echo ""
    echo "应该保留的元素："
    echo "  ✅ '制作.DS_Store模板'按钮"
    echo "  ✅ 背景图说明模块"
    echo "  ✅ 网站链接设置"
    echo ""
    
    read -p "UI元素是否正确？(y/n) " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_success "TC-E-003通过：UI元素正确"
        return 0
    else
        log_error "TC-E-003失败：UI元素有误"
        return 1
    fi
}

# TC-E-004: 无预制模板的批量处理
test_no_template() {
    print_header "TC-E-004: 无预制模板的批量处理"
    
    log_info "测试未制作模板时的行为"
    log_warning "此测试需要先删除已有模板"
    
    print_separator
    
    log_step "1. 删除现有模板（如果有）"
    
    if [ -n "$APP_PATH" ]; then
        RESOURCES_PATH="$APP_PATH/Contents/Resources"
        if [ -d "$RESOURCES_PATH/tools" ]; then
            TEMPLATE_PATH="$RESOURCES_PATH/tools/dmg-modifier/templates/.DS_Store"
        else
            TEMPLATE_PATH=""
        fi
        
        if [ -f "$TEMPLATE_PATH" ]; then
            echo "找到模板: $TEMPLATE_PATH"
            read -p "是否删除模板进行测试？(y/n) " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$TEMPLATE_PATH"
                log_success "模板已删除"
            else
                log_warning "跳过此测试"
                return 0
            fi
        fi
    fi
    
    log_step "2. 执行批量处理"
    log_manual "在应用中执行批量处理"
    echo ""
    echo "预期行为："
    echo "  - 处理应该成功"
    echo "  - 使用默认背景（或无背景）"
    echo "  - 没有崩溃或错误"
    echo ""
    wait_for_confirmation "批量处理完成？"
    
    read -p "是否正常处理？(y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_success "TC-E-004通过：无模板时正常处理"
        return 0
    else
        log_error "TC-E-004失败：无模板时异常"
        return 1
    fi
}

# TC-S-001: 路径诊断
test_path_diagnosis() {
    print_header "TC-S-001: 打包后路径诊断"
    
    log_info "诊断打包后的路径解析"
    
    if [ -z "$APP_PATH" ]; then
        log_warning "未找到打包应用，跳过诊断"
        return 0
    fi
    
    RESOURCES_PATH="$APP_PATH/Contents/Resources"
    
    print_separator
    
    log_step "1. 检查目录结构"
    echo ""
    echo "Resources目录结构："
    echo ""
    
    if [ -d "$RESOURCES_PATH" ]; then
        log_success "Resources 目录存在"
        
        # 检查app.asar
        if [ -f "$RESOURCES_PATH/app.asar" ]; then
            SIZE=$(stat -f%z "$RESOURCES_PATH/app.asar" 2>/dev/null || stat -c%s "$RESOURCES_PATH/app.asar" 2>/dev/null || echo "0")
            SIZE_MB=$((SIZE / 1024 / 1024))
            log_success "app.asar 存在 (${SIZE_MB}MB)"
        fi
        
        # 检查extraResources
        if [ -d "$RESOURCES_PATH/tools" ]; then
            log_success "tools 目录在 extraResources 中 ✅ 正确"
            
            # 列出关键文件
            echo ""
            echo "关键文件："
            if [ -f "$RESOURCES_PATH/tools/dmg-modifier/scripts/modify-dmg.sh" ]; then
                echo "  ✓ modify-dmg.sh"
            fi
            if [ -f "$RESOURCES_PATH/tools/dmg-modifier/templates/.DS_Store" ]; then
                echo "  ✓ .DS_Store"
            fi
            if [ -f "$RESOURCES_PATH/tools/dmg-modifier/templates/background.png" ]; then
                echo "  ✓ background.png"
            fi
        elif [ -d "$RESOURCES_PATH/app.asar.unpacked" ]; then
            log_warning "tools 可能在 app.asar.unpacked 中"
            
            if [ -d "$RESOURCES_PATH/app.asar.unpacked/tools" ]; then
                log_warning "确认：tools 在 app.asar.unpacked 中（不推荐）"
            fi
        else
            log_error "tools 目录不在 extraResources 中 ❌"
            log_error "这可能是Bug的根本原因！"
        fi
    fi
    
    print_separator
    
    log_step "2. 检查系统临时目录"
    SYSTEM_TEMP=$(mktemp -d 2>/dev/null || echo "/tmp")
    if [ -d "$SYSTEM_TEMP" ] && [ -w "$SYSTEM_TEMP" ]; then
        log_success "系统临时目录可用: $SYSTEM_TEMP"
    else
        log_error "系统临时目录不可用"
    fi
    
    # 清理
    if [[ "$SYSTEM_TEMP" == *"tmp."* ]]; then
        rm -rf "$SYSTEM_TEMP" 2>/dev/null || true
    fi
    
    print_separator
    
    log_info "路径诊断完成"
    log_info "如果发现问题，请参考《Electron打包路径问题_官方文档清单.md》"
}

# 主函数
main() {
    print_header "🎭 v1.1.64 E2E测试 - 打包环境完整流程"
    
    log_info "测试环境: $(uname -s)"
    log_info "测试日期: $(date)"
    log_info "测试类型: 端到端（E2E）测试"
    
    echo ""
    log_warning "E2E测试需要手动操作Electron GUI应用"
    log_info "请确保有足够的时间完成测试（约15-20分钟）"
    echo ""
    
    wait_for_confirmation "准备好开始测试？"
    
    # 检查应用安装
    if ! check_app_installation; then
        log_error "无法继续测试"
        exit 1
    fi
    
    # 测试计数
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    print_separator
    
    # TC-E-001: 开发环境完整流程（参考）
    read -p "是否执行开发环境测试作为对照？(y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if test_dev_flow; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
        total_tests=$((total_tests + 1))
    fi
    
    print_separator
    
    # TC-E-002: 打包环境完整流程 ⭐ 核心测试
    if test_packaged_flow; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
    
    print_separator
    
    # TC-E-003: UI元素验证
    if test_ui_elements; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
    
    print_separator
    
    # TC-E-004: 无预制模板测试（可选）
    read -p "是否测试无预制模板的情况？(y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if test_no_template; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
        total_tests=$((total_tests + 1))
    fi
    
    print_separator
    
    # TC-S-001: 路径诊断
    test_path_diagnosis
    
    # 打印测试摘要
    print_header "📊 E2E测试总结"
    
    echo "总测试数: $total_tests"
    echo -e "通过: ${GREEN}$passed_tests${NC}"
    echo -e "失败: ${RED}$failed_tests${NC}"
    echo ""
    
    if [ $failed_tests -eq 0 ] && [ $total_tests -gt 0 ]; then
        echo -e "${GREEN}✅ 所有E2E测试通过！${NC}"
        echo ""
        echo -e "${BOLD}${GREEN}🎉 v1.1.64 验收通过！${NC}"
        echo ""
        echo "核心功能验证："
        echo "  ✅ 打包后预制模板功能正常"
        echo "  ✅ UI元素删除正确"
        echo "  ✅ 完整业务流程可用"
        echo ""
        exit 0
    else
        echo -e "${RED}❌ 部分E2E测试失败${NC}"
        echo ""
        echo "请检查："
        echo "  1. 查看CDP日志定位问题"
        echo "  2. 运行单元测试和集成测试"
        echo "  3. 参考修复文档"
        echo ""
        exit 1
    fi
}

# 执行主函数
main "$@"