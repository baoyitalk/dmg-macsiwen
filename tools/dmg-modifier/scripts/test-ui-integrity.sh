#!/bin/bash
# DMG UI完整性测试 - 检测JavaScript运行时错误
# 用于捕获DOM元素不存在等问题

set -e

HTML_FILE="../../../electron/dmg-ui.html"
PASSED=0
FAILED=0
WARNINGS=0

echo "🔍 DMG UI完整性测试"
echo "检查HTML和JavaScript的一致性..."
echo ""

# 测试1: 提取所有getElementById调用
echo "━━━ 测试1: JavaScript引用的按钮ID ━━━"
JS_IDS=$(grep -o "getElementById('[^']*')" "$HTML_FILE" | sed "s/getElementById('//g" | sed "s/')//" | sort -u)

for id in $JS_IDS; do
  if grep -q "id=\"$id\"" "$HTML_FILE"; then
    echo "✅ $id - HTML中存在"
    ((PASSED++))
  else
    echo "❌ $id - HTML中不存在！（JavaScript会报错）"
    ((FAILED++))
  fi
done

# 测试2: 检查事件监听器与按钮的匹配
echo ""
echo "━━━ 测试2: 事件监听器完整性 ━━━"

# 检查已删除按钮的残留代码
DELETED_BUTTONS=("btnUploadBackground" "btnResetBackground")
for btn in "${DELETED_BUTTONS[@]}"; do
  if grep -q "getElementById('$btn')" "$HTML_FILE"; then
    echo "❌ $btn - 按钮已删除但JavaScript中还在引用！"
    ((FAILED++))
  else
    echo "✅ $btn - 无残留引用"
    ((PASSED++))
  fi
done

# 测试3: 核心功能按钮检查
echo ""
echo "━━━ 测试3: 核心功能按钮 ━━━"

CORE_BUTTONS=("btnMakeDsStore" "btnSaveWebsite" "btnProcess" "btnBatchProcess")
for btn in "${CORE_BUTTONS[@]}"; do
  has_html=$(grep -c "id=\"$btn\"" "$HTML_FILE" || true)
  has_js=$(grep -c "getElementById('$btn')" "$HTML_FILE" || true)
  
  if [ "$has_html" -gt 0 ] && [ "$has_js" -gt 0 ]; then
    echo "✅ $btn - HTML和JavaScript都存在"
    ((PASSED++))
  elif [ "$has_html" -eq 0 ] && [ "$has_js" -eq 0 ]; then
    echo "⚠️  $btn - HTML和JavaScript都不存在（可能是可选功能）"
    ((WARNINGS++))
  elif [ "$has_html" -gt 0 ] && [ "$has_js" -eq 0 ]; then
    echo "⚠️  $btn - HTML存在但JavaScript未绑定事件"
    ((WARNINGS++))
  else
    echo "❌ $btn - JavaScript引用但HTML不存在！"
    ((FAILED++))
  fi
done

# 测试4: 检查addEventListener是否在DOMContentLoaded内
echo ""
echo "━━━ 测试4: 事件绑定时机检查 ━━━"

# 检查btnMakeDsStore是否使用安全的绑定方式
if grep -A 5 "btnMakeDsStore = document.getElementById" "$HTML_FILE" | grep -q "if (!btnMakeDsStore)"; then
  echo "✅ btnMakeDsStore使用了null检查（安全）"
  ((PASSED++))
else
  echo "⚠️  btnMakeDsStore未使用null检查"
  ((WARNINGS++))
fi

# 测试报告
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 测试结果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 通过: $PASSED"
echo "❌ 失败: $FAILED"
echo "⚠️  警告: $WARNINGS"
echo ""

if [ $FAILED -gt 0 ]; then
  echo "❌ 测试失败！存在JavaScript运行时错误风险"
  exit 1
else
  echo "✅ UI完整性测试通过"
  exit 0
fi