#!/bin/bash
# DMG背景图功能全面测试
# 测试范围：脚本版本、Electron集成、.DS_Store验证

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }
print_header() { echo -e "\n${YELLOW}━━━ $1 ━━━${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$TOOL_DIR")")"
TEMPLATES_DIR="$TOOL_DIR/templates"
TEST_LOG="/tmp/dmg-test-$(date +%Y%m%d_%H%M%S).log"

TEST_PASSED=0
TEST_FAILED=0
TEST_WARNINGS=0

# 测试结果记录
log_test() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$TEST_LOG"
}

# ====================
# 测试1: 环境检查
# ====================
test_environment() {
  print_header "测试1: 环境检查"
  
  # 检查必要命令
  local commands=("hdiutil" "osascript" "strings")
  for cmd in "${commands[@]}"; do
    if command -v $cmd &> /dev/null; then
      print_success "$cmd 命令存在"
      log_test "PASS: $cmd command exists"
      ((++TEST_PASSED))
    else
      print_error "$cmd 命令不存在"
      log_test "FAIL: $cmd command not found"
      ((++TEST_FAILED))
    fi
  done
  
  # 检查脚本文件
  local scripts=("$SCRIPT_DIR/recreate-ds-store.sh" "$SCRIPT_DIR/modify-dmg.sh")
  for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
      print_success "$(basename "$script") 存在且可执行"
      log_test "PASS: $script exists and executable"
      ((++TEST_PASSED))
    else
      print_error "$(basename "$script") 不存在或不可执行"
      log_test "FAIL: $script missing or not executable"
      ((++TEST_FAILED))
    fi
  done
  
  # 检查模板目录
  if [ -d "$TEMPLATES_DIR" ]; then
    print_success "模板目录存在"
    log_test "PASS: templates directory exists"
    ((++TEST_PASSED))
  else
    print_error "模板目录不存在"
    log_test "FAIL: templates directory missing"
    ((++TEST_FAILED))
  fi
}

# ====================
# 测试2: 脚本语法检查
# ====================
test_script_syntax() {
  print_header "测试2: 脚本语法检查"
  
  if bash -n "$SCRIPT_DIR/recreate-ds-store.sh"; then
    print_success "recreate-ds-store.sh 语法正确"
    log_test "PASS: recreate-ds-store.sh syntax check"
    ((++TEST_PASSED))
  else
    print_error "recreate-ds-store.sh 语法错误"
    log_test "FAIL: recreate-ds-store.sh syntax error"
    ((++TEST_FAILED))
  fi
  
  if bash -n "$SCRIPT_DIR/modify-dmg.sh"; then
    print_success "modify-dmg.sh 语法正确"
    log_test "PASS: modify-dmg.sh syntax check"
    ((++TEST_PASSED))
  else
    print_error "modify-dmg.sh 语法错误"
    log_test "FAIL: modify-dmg.sh syntax error"
    ((++TEST_FAILED))
  fi
}

# ====================
# 测试3: 模板文件检查
# ====================
test_templates() {
  print_header "测试3: 模板文件检查"
  
  # 检查.DS_Store
  if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
    print_success ".DS_Store 模板存在"
    log_test "PASS: .DS_Store template exists"
    ((++TEST_PASSED))
    
    # 检查大小
    local size=$(stat -f%z "$TEMPLATES_DIR/.DS_Store")
    if [ $size -gt 1000 ]; then
      print_success ".DS_Store 大小正常 (${size} bytes)"
      log_test "PASS: .DS_Store size: $size bytes"
      ((++TEST_PASSED))
    else
      print_error ".DS_Store 太小，可能损坏 (${size} bytes)"
      log_test "FAIL: .DS_Store too small: $size bytes"
      ((++TEST_FAILED))
    fi
    
    # 检查内容
    if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "background"; then
      print_success ".DS_Store 包含背景图配置"
      log_test "PASS: .DS_Store contains background config"
      ((++TEST_PASSED))
    else
      print_error ".DS_Store 不包含背景图配置"
      log_test "FAIL: .DS_Store missing background config"
      ((++TEST_FAILED))
    fi
    
    # 检查是否包含绝对路径（不应该有）
    if strings "$TEMPLATES_DIR/.DS_Store" | grep -q "/Users/.*/Desktop"; then
      print_error "⚠️  .DS_Store 包含桌面绝对路径！"
      log_test "WARNING: .DS_Store contains desktop absolute path"
      ((++TEST_WARNINGS))
    else
      print_success ".DS_Store 不包含绝对路径"
      log_test "PASS: .DS_Store no absolute path"
      ((++TEST_PASSED))
    fi
  else
    print_error ".DS_Store 模板不存在"
    log_test "FAIL: .DS_Store template missing"
    ((++TEST_FAILED))
  fi
  
  # 检查背景图
  local bg_files=("$TEMPLATES_DIR/background.png" "$TEMPLATES_DIR/macsiwen-background.png")
  local bg_found=false
  for bg in "${bg_files[@]}"; do
    if [ -f "$bg" ]; then
      print_success "$(basename "$bg") 存在"
      log_test "PASS: $(basename "$bg") exists"
      ((++TEST_PASSED))
      bg_found=true
      
      # 检查文件格式
      if file "$bg" | grep -q "PNG\|JPEG"; then
        print_success "$(basename "$bg") 格式正确"
        log_test "PASS: $(basename "$bg") format valid"
        ((++TEST_PASSED))
      else
        print_error "$(basename "$bg") 格式不正确"
        log_test "FAIL: $(basename "$bg") format invalid"
        ((++TEST_FAILED))
      fi
    fi
  done
  
  if [ "$bg_found" = false ]; then
    print_error "背景图文件不存在"
    log_test "FAIL: No background image found"
    ((++TEST_FAILED))
  fi
  
  # 检查webloc文件
  if [ -f "$TEMPLATES_DIR/访问macsiwen.cc.webloc" ]; then
    print_success "webloc 文件存在"
    log_test "PASS: webloc file exists"
    ((++TEST_PASSED))
    
    # 检查内容
    if grep -q "macsiwen.cc" "$TEMPLATES_DIR/访问macsiwen.cc.webloc"; then
      print_success "webloc 包含正确URL"
      log_test "PASS: webloc contains correct URL"
      ((++TEST_PASSED))
    else
      print_error "webloc URL不正确"
      log_test "FAIL: webloc URL incorrect"
      ((++TEST_FAILED))
    fi
  else
    print_error "webloc 文件不存在"
    log_test "FAIL: webloc file missing"
    ((++TEST_FAILED))
  fi
}

# ====================
# 测试4: Electron集成检查
# ====================
test_electron_integration() {
  print_header "测试4: Electron集成检查"
  
  # 检查Electron文件
  local electron_files=(
    "$PROJECT_ROOT/electron/dmg-main.js"
    "$PROJECT_ROOT/electron/dmg-preload.js"
    "$PROJECT_ROOT/electron/dmg-ui.html"
  )
  
  for file in "${electron_files[@]}"; do
    if [ -f "$file" ]; then
      print_success "$(basename "$file") 存在"
      log_test "PASS: $(basename "$file") exists"
      ((++TEST_PASSED))
    else
      print_error "$(basename "$file") 不存在"
      log_test "FAIL: $(basename "$file") missing"
      ((++TEST_FAILED))
    fi
  done
  
  # 检查preload.js中的API
  if grep -q "dsStore:" "$PROJECT_ROOT/electron/dmg-preload.js"; then
    print_success "preload.js 包含dsStore API"
    log_test "PASS: preload.js has dsStore API"
    ((++TEST_PASSED))
  else
    print_error "preload.js 缺少dsStore API"
    log_test "FAIL: preload.js missing dsStore API"
    ((++TEST_FAILED))
  fi
  
  # 检查main.js中的handler
  if grep -q "start-ds-store-creation" "$PROJECT_ROOT/electron/dmg-main.js"; then
    print_success "dmg-main.js 包含.DS_Store处理器"
    log_test "PASS: dmg-main.js has DS_Store handler"
    ((++TEST_PASSED))
  else
    print_error "dmg-main.js 缺少.DS_Store处理器"
    log_test "FAIL: dmg-main.js missing DS_Store handler"
    ((++TEST_FAILED))
  fi
  
  # 检查UI中的按钮绑定（不能使用setTimeout延迟绑定）
  if grep -q "setTimeout.*btnMakeDsStore" "$PROJECT_ROOT/electron/dmg-ui.html"; then
    print_error "⚠️  UI使用了setTimeout延迟绑定（可能失败）"
    log_test "WARNING: UI uses setTimeout for event binding"
    ((++TEST_WARNINGS))
  else
    print_success "UI使用直接绑定（正确）"
    log_test "PASS: UI uses direct event binding"
    ((++TEST_PASSED))
  fi
  
  # 检查是否有调试日志
  if grep -q "console.log.*制作DS_Store" "$PROJECT_ROOT/electron/dmg-ui.html"; then
    print_success "UI包含调试日志"
    log_test "PASS: UI has debug logging"
    ((++TEST_PASSED))
  else
    print_error "UI缺少调试日志"
    log_test "FAIL: UI missing debug logging"
    ((++TEST_FAILED))
  fi
}

# ====================
# 测试5: 脚本功能模拟测试
# ====================
test_script_logic() {
  print_header "测试5: 脚本逻辑测试（模拟）"
  
  # 检查脚本中的关键函数
  local keywords=("BG_FILENAME=\"background.png\"" "POSIX file" "DropDMGBackground")
  
  for keyword in "${keywords[@]}"; do
    if grep -q "$keyword" "$SCRIPT_DIR/recreate-ds-store.sh"; then
      print_success "脚本包含关键逻辑: $keyword"
      log_test "PASS: Script contains: $keyword"
      ((++TEST_PASSED))
    else
      print_error "脚本缺少关键逻辑: $keyword"
      log_test "FAIL: Script missing: $keyword"
      ((++TEST_FAILED))
    fi
  done
  
  # 检查modify-dmg.sh是否使用正确的背景图
  if grep -q "background.png" "$SCRIPT_DIR/modify-dmg.sh"; then
    print_success "modify-dmg.sh 使用统一的背景图名称"
    log_test "PASS: modify-dmg.sh uses unified bg name"
    ((++TEST_PASSED))
  else
    print_error "modify-dmg.sh 背景图名称不统一"
    log_test "FAIL: modify-dmg.sh bg name mismatch"
    ((++TEST_FAILED))
  fi
}

# ====================
# 生成测试报告
# ====================
generate_report() {
  print_header "测试报告"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DMG背景图功能全面测试报告"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  print_success "通过: $TEST_PASSED 项"
  if [ $TEST_FAILED -gt 0 ]; then
    print_error "失败: $TEST_FAILED 项"
  else
    echo -e "${GREEN}失败: 0 项${NC}"
  fi
  if [ $TEST_WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  警告: $TEST_WARNINGS 项${NC}"
  else
    echo "警告: 0 项"
  fi
  echo ""
  echo "详细日志: $TEST_LOG"
  echo ""
  
  # 总体评估
  if [ $TEST_FAILED -eq 0 ]; then
    if [ $TEST_WARNINGS -eq 0 ]; then
      print_success "🎉 所有测试通过！可以验收！"
      log_test "RESULT: ALL TESTS PASSED - READY FOR ACCEPTANCE"
      echo ""
      echo "✅ 验收清单："
      echo "   1. 脚本版本正常"
      echo "   2. Electron集成正常"
      echo "   3. 模板文件正确"
      echo "   4. 无警告问题"
      echo ""
      return 0
    else
      echo -e "${YELLOW}⚠️  测试通过，但有警告需要注意${NC}"
      log_test "RESULT: TESTS PASSED WITH WARNINGS"
      echo ""
      echo "建议："
      echo "   - 检查警告项并修复"
      echo "   - 基本功能可以使用"
      echo ""
      return 0
    fi
  else
    print_error "❌ 测试失败！需要修复问题"
    log_test "RESULT: TESTS FAILED - ISSUES NEED FIX"
    echo ""
    echo "需要修复："
    echo "   - $TEST_FAILED 个失败项"
    echo "   - 修复后重新测试"
    echo ""
    return 1
  fi
}

# ====================
# 主测试流程
# ====================
main() {
  command -v clear >/dev/null 2>&1 && clear || true
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DMG背景图功能全面自动化测试"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
  print_info "测试日志: $TEST_LOG"
  echo ""
  
  log_test "========== DMG Background Test Start =========="
  log_test "Time: $(date)"
  
  # 执行所有测试
  test_environment
  test_script_syntax
  test_templates
  test_electron_integration
  test_script_logic
  
  # 生成报告
  generate_report
  
  log_test "========== DMG Background Test End =========="
}

main "$@"