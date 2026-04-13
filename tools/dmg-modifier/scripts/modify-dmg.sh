#!/bin/bash
# DMG文件修改脚本
# 用途：将第三方DMG中的品牌信息替换为macsiwen
# v1.0.0

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$TOOL_DIR/templates"
OUTPUT_DIR="$TOOL_DIR/output"
TEMP_DIR="$TOOL_DIR/temp"

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取挂载点中的 .app 相对路径快照（用于保证嵌套路径不变）
snapshot_app_paths() {
    local mount_root="$1"
    find "$mount_root" -type d -name "*.app" -print 2>/dev/null \
      | sed "s#^$mount_root/##" \
      | LC_ALL=C sort
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    if ! command -v hdiutil &> /dev/null; then
        print_error "hdiutil 未找到（macOS自带工具）"
        exit 1
    fi
    
    print_info "依赖检查通过"
}

# 清理临时文件
cleanup() {
    print_info "清理临时文件..."
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# 修改DMG文件
modify_dmg() {
    local input_dmg="$1"
    local output_name="$2"
    
    if [ ! -f "$input_dmg" ]; then
        print_error "输入文件不存在: $input_dmg"
        exit 1
    fi
    
    print_info "开始处理: $(basename "$input_dmg")"
    
    # 创建临时目录和输出目录
    print_info "创建临时目录: $TEMP_DIR"
    if ! mkdir -p "$TEMP_DIR" 2>&1; then
        print_error "无法创建临时目录: $TEMP_DIR"
        exit 1
    fi
    
    print_info "创建输出目录: $OUTPUT_DIR"
    if ! mkdir -p "$OUTPUT_DIR" 2>&1; then
        print_error "无法创建输出目录: $OUTPUT_DIR"
        exit 1
    fi
    
    # 验证目录是否存在
    if [ ! -d "$TEMP_DIR" ]; then
        print_error "临时目录创建失败: $TEMP_DIR"
        exit 1
    fi
    print_info "临时目录确认存在: $TEMP_DIR"
    
    # 1. 转换为可读写格式
    print_info "步骤1: 转换DMG为可读写格式..."
    print_info "输入文件: $input_dmg"
    
    local temp_dmg="$TEMP_DIR/temp.dmg"
    print_info "临时文件: $temp_dmg"
    
    # 如果临时文件已存在，先删除
    if [ -f "$temp_dmg" ]; then
        print_warn "临时文件已存在，删除旧文件..."
        rm -f "$temp_dmg"
    fi
    
    # 移除-quiet以查看详细错误
    print_info "执行 hdiutil convert..."
    
    # 执行hdiutil并捕获输出和退出码
    set +e  # 暂时禁用set -e，手动处理错误
    hdiutil convert "$input_dmg" -format UDRW -o "$temp_dmg" 2>&1
    local exit_code=$?
    set -e  # 重新启用set -e
    
    print_info "hdiutil退出码: $exit_code"
    print_info "立即检查临时目录内容:"
    ls -la "$TEMP_DIR" 2>&1 || print_error "临时目录不存在！"
    
    if [ $exit_code -ne 0 ]; then
        print_error "hdiutil convert 失败（退出码: $exit_code）"
        print_error "临时目录内容:"
        ls -la "$TEMP_DIR" 2>&1 || true
        cleanup
        exit 1
    fi
    
    # 验证输出文件是否生成
    # hdiutil convert会自动添加.dmg后缀，所以实际文件是 temp.dmg.dmg
    if [ -f "${temp_dmg}.dmg" ]; then
        # 重命名为不带双重.dmg的文件
        mv "${temp_dmg}.dmg" "$temp_dmg"
        print_info "转换成功（已重命名去除双重.dmg后缀）"
    elif [ -f "$temp_dmg" ]; then
        print_info "转换成功"
    else
        print_error "转换后的文件未找到"
        print_error "期望路径: $temp_dmg 或 ${temp_dmg}.dmg"
        print_error "临时目录内容:"
        ls -la "$TEMP_DIR" 2>&1 || true
        cleanup
        exit 1
    fi


    
    # 2. 挂载DMG
    print_info "步骤2: 挂载DMG..."
    local attach_output=$(hdiutil attach "$temp_dmg" -readwrite)
    local mount_device=$(echo "$attach_output" | grep "/Volumes/" | awk '{print $1}')
    local mount_point=$(echo "$attach_output" | awk -F '\t' '/\/Volumes\//{print $NF}' | tail -1)
    
    if [ -z "$mount_point" ] || [ -z "$mount_device" ]; then
        print_error "挂载失败"
        print_error "attach输出: $attach_output"
        cleanup
        exit 1
    fi
    
    print_info "挂载设备: $mount_device"
    print_info "挂载点: $mount_point"

    # 快照：品牌化前，记录所有 .app 的相对路径（支持嵌套目录）
    local app_paths_before="$TEMP_DIR/app-paths-before.txt"
    local app_paths_after="$TEMP_DIR/app-paths-after.txt"
    local app_paths_diff="$TEMP_DIR/app-paths-diff.txt"
    snapshot_app_paths "$mount_point" > "$app_paths_before"
    print_info "已记录品牌化前App路径快照"
    
    # 3. 替换品牌信息（在改卷标之前完成所有文件操作）
    print_info "步骤4: 替换品牌信息..."
    
    # 替换背景图（支持多种背景目录名称）
    print_info "查找背景目录..."
    local bg_dir=""
    local bg_dir_name=""
    for dir in ".background" ".DropDMGBackground" ".Background"; do
        if [ -d "$mount_point/$dir" ]; then
            bg_dir="$mount_point/$dir"
            bg_dir_name="$dir"
            print_info "✅ 发现背景目录: $dir"
            break
        fi
    done
    
    if [ -n "$bg_dir" ]; then
        if [ -f "$TEMPLATES_DIR/background.png" ]; then
            # 显示模板背景图信息
            local template_bg_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$TEMPLATES_DIR/background.png" 2>/dev/null || echo "未知")
            local template_bg_size=$(stat -f%z "$TEMPLATES_DIR/background.png" 2>/dev/null || echo "0")
            print_info "📝 模板background.png: ${template_bg_size}字节, 修改时间: ${template_bg_time}"
            
            # 删除所有旧背景图
            find "$bg_dir" -type f -delete 2>/dev/null || true
            print_info "已清空背景目录"
            
            # 复制新背景图（⭐ 同时复制png和tiff，兼容不同.DS_Store）
            local bg_copied=false
            if [ -f "$TEMPLATES_DIR/background.tiff" ]; then
                cp "$TEMPLATES_DIR/background.tiff" "$bg_dir/background.tiff" && bg_copied=true
                print_info "✅ 已复制background.tiff"
            fi
            if [ -f "$TEMPLATES_DIR/background.png" ]; then
                cp "$TEMPLATES_DIR/background.png" "$bg_dir/background.png" && bg_copied=true
                print_info "✅ 已复制background.png"
            fi
            
            if [ "$bg_copied" = true ]; then
                print_info "✅ 已替换背景图"
            else
                print_error "❌ 背景图复制失败：模板文件不存在"
            fi
        else
            print_warn "⚠️ 模板背景图不存在: $TEMPLATES_DIR/background.png"
        fi
    else
        # 如果没有背景目录，创建.DropDMGBackground目录（与.DS_Store模板一致）
        print_info "未找到背景目录，创建.DropDMGBackground"
        bg_dir_name=".DropDMGBackground"
        mkdir -p "$mount_point/.DropDMGBackground"
        
        # 复制两种格式的背景图
        local bg_copied=false
        if [ -f "$TEMPLATES_DIR/background.tiff" ]; then
            cp "$TEMPLATES_DIR/background.tiff" "$mount_point/.DropDMGBackground/background.tiff" && bg_copied=true
        fi
        if [ -f "$TEMPLATES_DIR/background.png" ]; then
            cp "$TEMPLATES_DIR/background.png" "$mount_point/.DropDMGBackground/background.png" && bg_copied=true
        fi
        
        if [ "$bg_copied" = true ]; then
            print_info "✅ 已创建并设置背景图"
        else
            print_error "❌ 创建背景图失败"
        fi
    fi
    
    # 删除上家的文件
    find "$mount_point" -name "*安装教程*.rtfd" -exec rm -rf {} \; 2>/dev/null || true
    rm -f "$mount_point/macsiwen.txt" 2>/dev/null || true
    print_info "✅ 已清理上家文件"
    
    # 添加访问网站链接
    if [ ! -f "$mount_point/访问macsiwen.cc.webloc" ]; then
        cat > "$mount_point/访问macsiwen.cc.webloc" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>URL</key>
	<string>https://macsiwen.cc</string>
</dict>
</plist>
EOF
        print_info "✅ 已添加访问网站链接"
    fi
    
    # 验证背景图文件存在
    print_info "✅ 背景图目录内容:"
    ls -la "$mount_point/$bg_dir_name/" 2>&1 | grep -E "(background|total)" || true
    
    # 替换二维码
    if [ -f "$TEMPLATES_DIR/qrcode.jpg" ]; then
        find "$mount_point" -name "*二维码*.jpg" -o -name "*二维码*.png" -o -name "qrcode.*" | while read qr_file; do
            cp "$TEMPLATES_DIR/qrcode.jpg" "$qr_file" 2>/dev/null || true
            print_info "已替换二维码: $(basename "$qr_file")"
        done
    else
        print_warn "模板二维码不存在: $TEMPLATES_DIR/qrcode.jpg"
    fi
    
    # 替换webloc文件
    if [ -f "$TEMPLATES_DIR/官网.webloc" ]; then
        find "$mount_point" -name "*官网*.webloc" | while read webloc_file; do
            cp "$TEMPLATES_DIR/官网.webloc" "$webloc_file" 2>/dev/null || true
            print_info "已替换官网链接: $(basename "$webloc_file")"
        done
    fi
    
    # 4. 删除旧的.DS_Store文件
    if [ -f "$mount_point/.DS_Store" ]; then
        print_info "删除旧的.DS_Store文件..."
        rm -f "$mount_point/.DS_Store" 2>/dev/null || print_warn "无法删除.DS_Store"
    fi
    
    # 5. 修改卷标名称（⭐ 关键修复：必须在复制.DS_Store之前改名！）
    print_info "步骤5: 修改卷标名称..."
    diskutil rename "$mount_point" "macsiwen.com" 2>/dev/null || print_warn "卷标修改失败（可能已是macsiwen.com）"
    
    # 更新挂载点路径（改名后路径会变）
    local new_mount_point=$(mount | awk -F ' on | \\(' '/\/Volumes\/macsiwen\.com/{print $2}' | tail -1)
    if [ -n "$new_mount_point" ]; then
        mount_point="$new_mount_point"
        print_info "更新挂载点: $mount_point"
    fi
    
    # 检查挂载点是否可写，如果不可写则重新挂载
    if [ ! -w "$mount_point" ]; then
        print_warn "挂载点变为只读，尝试重新挂载为可读写..."
        hdiutil detach "$mount_device" -force
        sleep 1
        local attach_output=$(hdiutil attach "$temp_dmg" -readwrite)
        mount_device=$(echo "$attach_output" | grep "/Volumes/" | awk '{print $1}')
        mount_point=$(echo "$attach_output" | awk -F '\t' '/\/Volumes\//{print $NF}' | tail -1)
        print_info "重新挂载完成: $mount_point"
    fi
    
    # 6. 复制预制的.DS_Store文件（⭐ 关键修复：在改名后复制，确保路径匹配！）
    if [ -f "$TEMPLATES_DIR/.DS_Store" ]; then
        print_info "步骤6: 复制预制的.DS_Store文件..."
        
        # 显示模板.DS_Store信息
        local template_ds_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$TEMPLATES_DIR/.DS_Store" 2>/dev/null || echo "未知")
        local template_ds_size=$(stat -f%z "$TEMPLATES_DIR/.DS_Store" 2>/dev/null || echo "0")
        print_info "📝 模板.DS_Store: ${template_ds_size}字节, 修改时间: ${template_ds_time}"
        
        # 复制（此时挂载点已经是 /Volumes/macsiwen.com/）
        cp "$TEMPLATES_DIR/.DS_Store" "$mount_point/.DS_Store"
        
        # 验证复制结果
        if [ -f "$mount_point/.DS_Store" ]; then
            local ds_size=$(stat -f%z "$mount_point/.DS_Store" 2>/dev/null || echo "0")
            local ds_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$mount_point/.DS_Store" 2>/dev/null || echo "未知")
            print_info "✅ .DS_Store已复制到正确挂载点，大小: ${ds_size}字节, 时间: ${ds_time}"
        else
            print_warn "⚠️ .DS_Store复制失败"
        fi
    else
        print_warn "⚠️ 模板.DS_Store不存在: $TEMPLATES_DIR/.DS_Store"
        print_warn "背景图和布局将使用默认设置"
    fi

    # 路径保护：品牌化后再次快照，确保 .app 路径（包括嵌套目录）完全一致
    snapshot_app_paths "$mount_point" > "$app_paths_after"
    if ! diff -u "$app_paths_before" "$app_paths_after" > "$app_paths_diff"; then
        print_error "❌ 检测到 App 路径变化，已中止输出（要求：嵌套目录路径不变）"
        cat "$app_paths_diff"
        hdiutil detach "$mount_device" -force 2>/dev/null || true
        cleanup
        exit 1
    fi
    print_info "✅ App 路径校验通过（嵌套目录路径保持不变）"
    
    # 7. 卸载DMG（使用设备名而不是路径，避免多个同名挂载点冲突）
    print_info "步骤7: 卸载DMG..."
    print_info "卸载设备: $mount_device"
    hdiutil detach "$mount_device" -force
    sleep 2
    
    # 8. 压缩为最终格式（使用低压缩级别避免segfault）
    print_info "步骤8: 压缩为最终DMG（压缩率约60%）..."
    local output_dmg="$OUTPUT_DIR/$output_name"
    
    # 如果输出文件已存在，重命名旧文件（保留历史版本）
    if [ -f "$output_dmg" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_name="${output_name%.dmg}_backup_${timestamp}.dmg"
        local backup_path="$OUTPUT_DIR/$backup_name"
        print_warn "输出文件已存在，重命名为: $backup_name"
        mv "$output_dmg" "$backup_path"
    fi
    
    hdiutil convert "$temp_dmg" -format UDZO -imagekey zlib-level=1 -o "$output_dmg"
    
    print_info "✅ 完成! 输出文件: $output_dmg"
    
    # 清理临时文件（每次处理成功后）
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        print_info "已清理临时文件"
    fi
}

# 批量处理
batch_modify() {
    local input_dir="$1"
    
    if [ ! -d "$input_dir" ]; then
        print_error "输入目录不存在: $input_dir"
        exit 1
    fi
    
    print_info "批量处理目录: $input_dir"
    
    local count=0
    find "$input_dir" -name "*.dmg" -type f | while read dmg_file; do
        local basename=$(basename "$dmg_file" .dmg)
        local output_name="${basename}-macsiwen.dmg"
        
        print_info "处理 ($((++count))): $basename"
        modify_dmg "$dmg_file" "$output_name"
    done
    
    print_info "批量处理完成，共处理 $count 个文件"
}

# 主函数
main() {
    echo "================================"
    echo "  DMG品牌信息替换工具"
    echo "  macsiwen v1.0.0"
    echo "================================"
    echo ""
    
    check_dependencies
    
    if [ $# -eq 0 ]; then
        echo "用法:"
        echo "  单个文件: $0 <input.dmg> [output.dmg]"
        echo "  批量处理: $0 --batch <input_dir>"
        echo ""
        echo "示例:"
        echo "  $0 'iShot Pro 2.5.8.dmg'"
        echo "  $0 'iShot Pro 2.5.8.dmg' 'iShot-Pro-macsiwen.dmg'"
        echo "  $0 --batch ~/Downloads/dmg-files"
        exit 1
    fi
    
    if [ "$1" == "--batch" ]; then
        batch_modify "$2"
    else
        local input_dmg="$1"
        local output_name="${2:-$(basename "$input_dmg" .dmg)-macsiwen.dmg}"
        modify_dmg "$input_dmg" "$output_name"
    fi
}

# 只在脚本真正退出时清理（不在函数返回时触发）
trap 'cleanup' INT TERM

main "$@"

# 脚本结束时手动清理
cleanup
