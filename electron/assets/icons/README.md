# Electron应用图标

## 图标要求

### macOS (.icns)
- 文件名：`icon.icns`
- 包含多个尺寸：16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
- 使用工具：`iconutil` (macOS自带) 或 在线转换工具

### Windows (.ico)
- 文件名：`icon.ico`
- 包含多个尺寸：16x16, 32x32, 48x48, 256x256
- 使用工具：ImageMagick 或 在线转换工具

### Linux (.png)
- 文件名：`icon.png`
- 尺寸：至少512x512，推荐1024x1024
- 格式：PNG with transparency

## 如何生成图标

### 方法1：使用在线工具
1. 访问 https://www.icoconverter.com/ 或 https://cloudconvert.com/
2. 上传您的logo图片（PNG格式，1024x1024）
3. 转换为 .icns (macOS) 和 .ico (Windows)
4. 将文件保存到此目录

### 方法2：使用命令行工具

#### macOS (.icns)
```bash
# 1. 准备不同尺寸的PNG文件
mkdir icon.iconset
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

# 2. 生成.icns文件
iconutil -c icns icon.iconset -o icon.icns

# 3. 清理
rm -rf icon.iconset
```

#### Windows (.ico)
```bash
# 使用ImageMagick
convert icon.png -define icon:auto-resize=256,128,96,64,48,32,16 icon.ico
```

## 当前logo

请将您的logo图片（圆形设计，带React原子图标）保存为：
- `icon.png` (1024x1024, PNG格式)
- `icon.icns` (macOS格式)
- `icon.ico` (Windows格式)

## 验证

构建应用后，图标会显示在：
- macOS: 应用程序图标、Dock图标、DMG图标
- Windows: 应用程序图标、任务栏图标
- Linux: 应用程序图标

## 注意事项

1. 确保图标背景透明（PNG格式）
2. 图标设计应该在小尺寸（16x16）下仍然清晰可辨
3. 避免过于复杂的细节
4. 使用高对比度的颜色
5. 圆形设计在macOS上效果最好
