#!/bin/bash

# v1.1.64 测试汇总脚本
# 测试目标：按照测试金字塔结构依次运行所有测试
# 测试层次：单元测试(60%) → 集成测试(30%) → E2E测试(10%)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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

# 打印测试头部
print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 打印测试金字塔
print_test_pyramid() {
    echo ""
    echo "           📊 测试金字塔"
    echo ""
    echo "            E2E测试 (10%)"
    echo "           ━━━━━━━━━━━━"
    echo "          /              \\"
    echo "         /   集成测试 (30%) \\"
    echo "        /━━━━━━━━━━━━━━━━━━━━\\"
    echo "       /                      \\"
    echo "      /    单元测试 (60%)       \\"
    echo "     /━━━━━━━━━━━━━━━━━━━━━━━━━━\\"
    echo ""
}

# 打印测试摘要
print_summary() {
    local total=$1
    local passed=$2
    local failed=$3
    
    print_header "📊 测试汇总"
    
    echo "总测试脚本: $total"
    echo -e "通过: ${GREEN}$passed${NC}"
    echo -e "失败: ${RED}$failed${NC}"
    echo ""
    
    if [ $failed -eq 0 ]; then
        echo -e "${BOLD}${GREEN}✅ 所有测试通过！${NC}"
        echo ""
        echo "测试覆盖："
        echo "  ✓ 单元测试：路径解析、配置验证"
        echo "  ✓ 集成测试：模块间交互"
        echo "  ✓ E2E测试：完整业务流程"
        echo ""
        echo -e "${BOLD}${GREEN}🎉 v1.1.64 准备就绪！${NC}"
        echo ""
    else
        echo -e "${BOLD}${RED}❌ 部分测试失败${NC}"
        echo ""
        echo "请检查失败的测试脚本输出"
        echo ""
    fi
}

# 主函数
main() {
    print_header "🧪 v1.1.64 测试套件 - 打包环境验证"
    
    log_info "测试环境: $(uname -s)"
    log_info "测试日期: $(date)"
    log_info "项目根目录: $PROJECT_ROOT"
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    print_test_pyramid
    
    log_info "按测试金字塔结构执行测试..."
    echo ""
    
    # 测试计数
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # ========================================
    # 第1层：单元测试（60%）
    # ========================================
    print_header "第1层：单元测试 (60%)"
    
    log_info "执行单元测试..."
    log_info "测试脚本: test-unit-packaging.sh"
    echo ""
    
    total_tests=$((total_tests + 1))
    
    if "$SCRIPT_DIR/test-unit-packaging.sh"; then
        log_success "单元测试通过"
        passed_tests=$((passed_tests + 1))
    else
        log_error "单元测试失败"
        failed_tests=$((failed_tests + 1))
        
        log_warning "单元测试失败，建议先修复基础问题再继续"
        read -p "是否继续集成测试？(y/n) " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "测试中止"
            exit 1
        fi
    fi
    
    echo ""
    echo "按回车键继续..."
    read -r
    
    # ========================================
    # 第2层：集成测试（30%）
    # ========================================
    print_header "第2层：集成测试 (30%)"
    
    log_info "执行集成测试..."
    log_info "测试脚本: test-integration-packaging.sh"
    echo ""
    
    total_tests=$((total_tests + 1))
    
    if "$SCRIPT_DIR/test-integration-packaging.sh"; then
        log_success "集成测试通过"
        passed_tests=$((passed_tests + 1))
    else
        log_error "集成测试失败"
        failed_tests=$((failed_tests + 1))
        
        log_warning "集成测试失败，建议先修复模块交互问题"
        read -p "是否继续E2E测试？(y/n) " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "测试中止"
            exit 1
        fi
    fi
    
    echo ""
    echo "按回车键继续..."
    read -r
    
    # ========================================
    # 第3层：E2E测试（10%）
    # ========================================
    print_header "第3层：E2E测试 (10%)"
    
    log_warning "E2E测试需要手动操作GUI应用"
    log_info "预计耗时：15-20分钟"
    echo ""
    
    read -p "是否执行E2E测试？(y/n) " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "执行E2E测试..."
        log_info "测试脚本: test-e2e-packaging.sh"
        echo ""
        
        total_tests=$((total_tests + 1))
        
        if "$SCRIPT_DIR/test-e2e-packaging.sh"; then
            log_success "E2E测试通过"
            passed_tests=$((passed_tests + 1))
        else
            log_error "E2E测试失败"
            failed_tests=$((failed_tests + 1))
        fi
    else
        log_warning "跳过E2E测试"
        echo ""
        echo "提示：E2E测试是最终验收的关键步骤"
        echo "建议在修复所有bug后执行E2E测试"
    fi
    
    # 打印测试摘要
    print_summary $total_tests $passed_tests $failed_tests
    
    # 返回退出码
    if [ $failed_tests -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 执行主函数
main "$@"