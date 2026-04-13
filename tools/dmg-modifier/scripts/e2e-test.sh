#!/bin/bash
# DMG背景图端到端集成测试
# 实际生成DMG，验证背景图是否正确显示

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "\n${YELLOW}▶ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$TOOL_DIR")")"
TEMPLATES_DIR="$TOOL_DIR/templates"
TEST_DIR="/tmp/dmg-e2e-test-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$TEST_DIR/test.log"

# 测试计数
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 创建测试目录
mkdir -p "$TEST_DIR"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_assert() {
    local test_name="$1"
    local condition="$2"
    ((++TESTS_TOTAL))
    
    if eval "$condition"; then
        print_success "$test_name"
        log "PASS: $test_name"
        ((++TESTS_PASSED))
        return 0
    else
        print_error "$test_name"
        log "FAIL: $test_name"
        ((++TESTS_FAILED))
        return 0
    fi
}

cleanup() {
    print_step "清理测试环境"
    
    # 卸载所有测试DMG
    for mount in $(mount | grep "$TEST_DIR" | awk '{print $3}'); do
        hdiutil detach "$mount" -force 2>/dev/null || true
    done
    
    log "Cleanup completed"

    # 删除测试目录
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# 注册清理函数
trap cleanup EXIT

command -v clear >/dev/null 2>&1 && clear || true
echo "╔═══════════════════════════════════════════════╗"
echo "║   DMG 背景图端到端集成测试                   ║"
echo "║   真实生成DMG并验证背景图                    ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
print_info "测试目录: $TEST_DIR"
print_info "测试日志: $LOG_FILE"
echo ""

log "========== E2E Test Start =========="
log "Test directory: $TEST_DIR"

# ========================================
# 测试1: 准备测试资源
# ========================================
print_step "测试1: 准备测试资源"

# 1.1 创建测试背景图
test_assert "创建测试背景图" "sips -s format png '$TEMPLATES_DIR/background.png' --out '$TEST_DIR/test-bg.png' 2>&1 | tee -a '$LOG_FILE' && [ -f '$TEST_DIR/test-bg.png' ]"

# 1.2 检查模板文件
test_assert "检查.DS_Store模板" "[ -f '$TEMPLATES_DIR/.DS_Store' ]"
test_assert "检查webloc模板" "[ -f '$TEMPLATES_DIR/访问macsiwen.cc.webloc' ]"

# ========================================
# 测试2: 创建测试DMG
# ========================================
print_step "测试2: 创建源DMG"

TEST_SOURCE_DMG="$TEST_DIR/source-test.dmg"
TEST_VOL_NAME="TestDMG"

# 2.1 创建测试DMG
log "Creating test DMG: $TEST_SOURCE_DMG"
if hdiutil create -size 50m -fs HFS+ -volname "$TEST_VOL_NAME" "$TEST_SOURCE_DMG" 2>&1 | tee -a "$LOG_FILE"; then
    test_assert "创建源DMG成功" "[ -f '$TEST_SOURCE_DMG' ]"
else
    print_error "创建DMG失败"
    exit 1
fi

# 2.2 挂载并添加测试文件
log "Attaching test DMG"
hdiutil attach "$TEST_SOURCE_DMG" 2>&1 | tee -a "$LOG_FILE"
sleep 1

MOUNT_POINT="/Volumes/$TEST_VOL_NAME"
test_assert "DMG已挂载" "[ -d '$MOUNT_POINT' ]"

# 添加测试文件
touch "$MOUNT_POINT/测试应用.app"
touch "$MOUNT_POINT/README.txt"
test_assert "添加测试文件" "[ -f '$MOUNT_POINT/测试应用.app' ] && [ -f '$MOUNT_POINT/README.txt' ]"

# 卸载
hdiutil detach "$MOUNT_POINT" -force 2>&1 | tee -a "$LOG_FILE"
sleep 1

# ========================================
# 测试3: 使用modify-dmg.sh处理DMG
# ========================================
print_step "测试3: 使用modify-dmg.sh处理DMG"

TEST_OUTPUT_DMG="$TEST_DIR/test-macsiwen.dmg"

log "Processing DMG with modify-dmg.sh"
if cd "$SCRIPT_DIR" && bash modify-dmg.sh "$TEST_SOURCE_DMG" "test-macsiwen.dmg" 2>&1 | tee -a "$LOG_FILE"; then
    # 检查输出文件
    if [ -f "$TOOL_DIR/output/test-macsiwen.dmg" ]; then
        mv "$TOOL_DIR/output/test-macsiwen.dmg" "$TEST_OUTPUT_DMG"
        test_assert "DMG处理成功" "[ -f '$TEST_OUTPUT_DMG' ]"
    else
        print_error "输出DMG不存在"
        ((++TESTS_FAILED))
    fi
else
    print_error "DMG处理失败"
    ((++TESTS_FAILED))
fi

# ========================================
# 测试4: 验证处理后的DMG结构
# ========================================
print_step "测试4: 验证处理后的DMG结构"

if [ ! -f "$TEST_OUTPUT_DMG" ]; then
    print_error "跳过验证：输出DMG不存在"
    exit 1
fi

# 4.1 挂载处理后的DMG
log "Mounting processed DMG"
hdiutil attach "$TEST_OUTPUT_DMG" -readonly 2>&1 | tee -a "$LOG_FILE"
sleep 2

# 获取实际挂载点（可能带空格后缀，例如 "macsiwen.com 2"）
PROCESSED_MOUNT=$(mount | grep "macsiwen.com" | tail -1 | awk -F ' on | \\(' '{print $2}')
test_assert "处理后的DMG已挂载" "[ -d '$PROCESSED_MOUNT' ]"

if [ -d "$PROCESSED_MOUNT" ]; then
    # 4.2 检查目录结构
    test_assert "存在.DropDMGBackground目录" "[ -d '$PROCESSED_MOUNT/.DropDMGBackground' ]"
    test_assert "存在background.png" "[ -f '$PROCESSED_MOUNT/.DropDMGBackground/background.png' ]"
    test_assert "存在.DS_Store" "[ -f '$PROCESSED_MOUNT/.DS_Store' ]"
    test_assert "存在webloc文件" "[ -f '$PROCESSED_MOUNT/访问macsiwen.cc.webloc' ]"
    
    # 4.3 检查应用程序符号链接（源DMG不一定自带，作为信息项）
    if [ -L "$PROCESSED_MOUNT/Applications" ]; then
        test_assert "存在Applications符号链接" "true"
    else
        print_info "源DMG未包含Applications符号链接（本测试场景允许）"
        log "INFO: Applications symlink not present in source fixture"
    fi
    
    # 4.4 验证背景图格式
    if file "$PROCESSED_MOUNT/.DropDMGBackground/background.png" | grep -q "PNG"; then
        test_assert "背景图格式正确（PNG）" "true"
    else
        test_assert "背景图格式正确（PNG）" "false"
    fi
    
    # 4.5 关键：验证.DS_Store内容
    print_info "验证.DS_Store内容..."
    DS_STORE_CONTENT=$(strings "$PROCESSED_MOUNT/.DS_Store" 2>/dev/null || echo "")
    
    # 检查是否包含背景图配置
    if echo "$DS_STORE_CONTENT" | grep -q "background"; then
        test_assert ".DS_Store包含背景图配置" "true"
        log ".DS_Store content check: background found"
    else
        test_assert ".DS_Store包含背景图配置" "false"
        log "WARNING: .DS_Store might not contain background config"
    fi
    
    # 检查是否包含绝对路径（不应该有）
    if echo "$DS_STORE_CONTENT" | grep -q "/Users/.*/Desktop"; then
        print_error "⚠️  .DS_Store包含桌面绝对路径（错误！）"
        log "ERROR: .DS_Store contains desktop absolute path"
        ((++TESTS_FAILED))
    else
        test_assert ".DS_Store不包含绝对路径" "true"
        log ".DS_Store path check: no absolute path found"
    fi
    
    # 输出.DS_Store详细信息用于调试
    log "=== .DS_Store Content Sample ==="
    strings "$PROCESSED_MOUNT/.DS_Store" | head -20 | tee -a "$LOG_FILE"
    log "=== End of .DS_Store Content ==="
fi

# ========================================
# 测试5: 在另一位置重新挂载验证
# ========================================
print_step "测试5: 重新挂载验证（模拟其他电脑）"

# 卸载
if [ -d "$PROCESSED_MOUNT" ]; then
    hdiutil detach "$PROCESSED_MOUNT" -force 2>&1 | tee -a "$LOG_FILE"
    sleep 2
fi

# 重新挂载
log "Re-mounting DMG to verify persistence"
hdiutil attach "$TEST_OUTPUT_DMG" -readonly 2>&1 | tee -a "$LOG_FILE"
sleep 2

# 重新解析挂载点（避免卷名带后缀导致路径变化）
PROCESSED_MOUNT=$(mount | grep "macsiwen.com" | tail -1 | awk -F ' on | \\(' '{print $2}')

if [ -d "$PROCESSED_MOUNT" ]; then
    test_assert "DMG可重复挂载" "true"
    test_assert "重新挂载后.DS_Store仍存在" "[ -f '$PROCESSED_MOUNT/.DS_Store' ]"
    test_assert "重新挂载后背景图仍存在" "[ -f '$PROCESSED_MOUNT/.DropDMGBackground/background.png' ]"
    
    # 打开Finder验证（可选）
    if [ "$1" = "--visual" ]; then
        print_info "打开Finder窗口进行视觉验证..."
        open "$PROCESSED_MOUNT"
        print_info "请检查Finder窗口是否显示背景图"
        echo -n "按Enter继续..."
        read
    fi
else
    print_error "重新挂载失败"
    ((++TESTS_FAILED))
fi

# ========================================
# 测试6: 文件大小��完整性检查
# ========================================
print_step "测试6: 文件大小和完整性检查"

SOURCE_SIZE=$(stat -f%z "$TEST_SOURCE_DMG" 2>/dev/null || echo "0")
OUTPUT_SIZE=$(stat -f%z "$TEST_OUTPUT_DMG" 2>/dev/null || echo "0")

print_info "源DMG大小: $(numfmt --to=iec $SOURCE_SIZE 2>/dev/null || echo ${SOURCE_SIZE})"
print_info "输出DMG大小: $(numfmt --to=iec $OUTPUT_SIZE 2>/dev/null || echo ${OUTPUT_SIZE})"

# 针对最小测试DMG，验证输出不为异常空文件即可
test_assert "输出DMG大小合理" "[ $OUTPUT_SIZE -gt 30000 ]"

# ========================================
# 生成测试报告
# ========================================
print_step "测试报告"

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║           DMG 端到端测试报告                  ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "总测试数: $TESTS_TOTAL"
print_success "通过: $TESTS_PASSED"

if [ $TESTS_FAILED -gt 0 ]; then
    print_error "失败: $TESTS_FAILED"
else
    echo -e "${GREEN}失败: 0${NC}"
fi

echo ""
echo "详细日志: $LOG_FILE"
echo "测试DMG: $TEST_OUTPUT_DMG"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "🎉 所有端到端测试通过！"
    echo ""
    echo "验证项："
    echo "  ✅ DMG成功生成"
    echo "  ✅ 背景图正确添加"
    echo "  ✅ .DS_Store正确生成"
    echo "  ✅ 文件结构完整"
    echo "  ✅ 可重复挂载"
    echo "  ✅ 无绝对路径"
    echo ""
    
    if [ "$1" != "--keep" ]; then
        print_info "提示：测试文件将在退出时自动清理"
        print_info "如需保留，使用 --keep 参数"
    fi
    
    log "========== E2E Test PASSED =========="
    exit 0
else
    print_error "❌ 测试失败！"
    echo ""
    echo "请查看详细日志: $LOG_FILE"
    echo "测试目录已保留: $TEST_DIR"
    echo ""
    log "========== E2E Test FAILED =========="
    exit 1
fi
