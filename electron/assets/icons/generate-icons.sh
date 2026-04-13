#!/bin/bash
# 生成Electron应用图标脚本
# 使用方法：./generate-icons.sh icon-source.png

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ -z "$1" ]; then
    print_error "请提供源图片文件"
    echo "使用方法: $0 icon-source.png"
    exit 1
fi

SOURCE_IMAGE="$1"

# 检查源文件是否存在
if [ ! -f "$SOURCE_IMAGE" ]; then
    print_error "源文件不存在: $SOURCE_IMAGE"
    exit 1
fi

print_info "源图片: $SOURCE_IMAGE"

# 检查依赖
if ! command -v sips &> /dev/null; then
    print_error "sips 命令未找到（macOS自带工具）"
    exit 1
fi

# 1. 生成标准PNG图标
print_info "生成 icon.png (1024x1024)..."
sips -z 1024 1024 "$SOURCE_IMAGE" --out icon.png

# 2. 生成macOS .icns图标
print_info "生成 macOS .icns 图标..."

# 创建iconset目录
mkdir -p icon.iconset

# 生成不同尺寸
print_info "生成不同尺寸的图标..."
sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png

# 生成.icns文件
print_info "转换为 .icns 格式..."
iconutil -c icns icon.iconset -o icon.icns

# 清理iconset目录
rm -rf icon.iconset

# 3. 生成Windows .ico图标
print_info "生成 Windows .ico 图标..."
if command -v convert &> /dev/null; then
    convert icon.png -define icon:auto-resize=256,128,96,64,48,32,16 icon.ico
    print_info "✅ icon.ico 生成成功"
else
    print_warn "ImageMagick 未安装，跳过 .ico 生成"
    print_warn "请访问 https://www.icoconverter.com/ 手动转换"
fi

# 完成
print_info "========================================="
print_info "✅ 图标生成完成！"
print_info "========================================="
print_info "生成的文件:"
print_info "  - icon.png  (1024x1024, 用于Linux)"
print_info "  - icon.icns (macOS应用图标)"
if [ -f "icon.ico" ]; then
    print_info "  - icon.ico  (Windows应用图标)"
fi
print_info ""
print_info "现在可以运行以下命令构建应用:"
print_info "  npm run electron:build:mac"
print_info "  npm run electron:build:win"
print_info "  npm run electron:build:linux"
