# DMG品牌化工具

## 功能

将第三方Mac软件DMG中的品牌信息替换为macsiwen品牌，支持自定义布局和批量处理。

## 🚀 快速开始

### 方式1：一键自定义布局（推荐）
```bash
cd tools/dmg-modifier/scripts
./start-custom-layout.sh
```
交互式引导完成：创建模板 → 调整布局 → 提取配置 → 测试效果

### 方式2：使用现有布局
```bash
cd tools/dmg-modifier/scripts
./modify-dmg.sh "xxx.dmg"
```

### 方式3：Web界面
访问：http://localhost:3002/shop/admin/dmg-editor

## 📁 目录结构

```
dmg-modifier/
├── scripts/
│   ├── modify-dmg.sh              # 主处理脚本
│   ├── create-template-dmg.sh     # 创建模板DMG（自定义布局）
│   ├── extract-ds-store.sh        # 提取.DS_Store文件
│   └── start-custom-layout.sh     # 一键启动自定义布局流程
├── templates/                      # 替换素材模板
│   ├── background.png             # DMG背景图
│   ├── qrcode.jpg                # 公众号二维码
│   ├── 官网.webloc                # 官网链接
│   ├── macsiwen.txt              # 品牌说明文件
│   └── .DS_Store                 # 自定义布局配置（可选）
├── output/                        # 输出目录（自动创建）
├── temp/                          # 临时目录（自动创建和清理）
├── DMG_BRANDING_SOLUTION.md      # 完整方案文档
├── CUSTOM_LAYOUT_GUIDE.md        # 自定义布局指南
└── QUICK_REFERENCE.md            # 快速参考
```

## 使用方法

### 1. 准备素材

在 `templates/` 目录下放置以下文件：

#### 必需文件：
- **qrcode.jpg** - 你的公众号二维码（建议尺寸：400x400px）
- **background.png** - DMG背景图（可选，尺寸：600x400px或800x500px）

#### 背景图设计建议：
```
┌─────────────────────────────────────────┐
│                                         │
│   [App图标]  ────→  [Applications]     │
│    (留空)              (留空)           │
│                                         │
│                                         │
│   ┌─────────┐                          │
│   │ [二维码] │      macsiwen            │
│   │         │      Mac软件资源站        │
│   └─────────┘                          │
└─────────────────────────────────────────┘
```

### 2. 单个文件处理

```bash
# 基本用法（输出文件名自动添加-macsiwen后缀）
./scripts/modify-dmg.sh "/path/to/iShot Pro 2.5.8.dmg"

# 指定输出文件名
./scripts/modify-dmg.sh "/path/to/iShot Pro 2.5.8.dmg" "iShot-Pro-macsiwen.dmg"
```

### 3. 批量处理

```bash
# 批量处理某个目录下的所有DMG文件
./scripts/modify-dmg.sh --batch ~/Downloads/dmg-files
```

### 4. 实际操作示例

```bash
# 示例1：处理单个DMG
cd /Users/johnpeng/career_data/code/vcommerce-project/xianyu-toolbox/tools/dmg-modifier
./scripts/modify-dmg.sh '/Users/johnpeng/Downloads/iShot Pro 2.5.8.dmg'

# 示例2：批量处理Downloads目录
./scripts/modify-dmg.sh --batch ~/Downloads
```

## 工作流程

脚本会自动执行以下步骤：

1. ✅ 转换DMG为可读写格式（UDRW）
2. ✅ 挂载DMG
3. ✅ 修改卷标名称：MacWk.CN → macsiwen.com
4. ✅ 替换品牌信息：
   - 替换背景图（如果存在 `.background/` 目录）
   - 替换二维码文件
   - 替换官网链接（.webloc文件）
   - 添加macsiwen品牌说明文件
5. ✅ 卸载DMG
6. ✅ 压缩为最终格式（UDZO，压缩率约60%）
7. ✅ 清理临时文件

## 输出位置

处理后的DMG文件保存在 `output/` 目录下。

## 注意事项

### ⚠️ 重要提示

1. **版权问题**：
   - 仅用于个人学习和测试
   - 不要用于商业分发
   - 尊重原软件版权

2. **代码签名**：
   - 修改后的DMG会失去原有的代码签名
   - 用户首次打开可能需要在"系统偏好设置 > 安全性与隐私"中允许

3. **文件大小**：
   - 处理大文件（>1GB）可能需要较长时间
   - 确保有足够的磁盘空间（至少是DMG文件大小的3倍）

4. **兼容性**：
   - 仅支持macOS系统
   - 需要macOS 10.13+

## 素材准备指南

### 二维码（qrcode.jpg）

```bash
# 推荐尺寸：400x400px
# 格式：JPG或PNG
# 内容：你的公众号/网站二维码
```

### 背景图（background.png）

可以使用以下工具制作：
- **Sketch** / **Figma** - 专业设计工具
- **Pixelmator Pro** - Mac原生图像编辑器
- **Canva** - 在线设计工具

参考模板：
```
尺寸：800x500px
背景：渐变或纯色
元素：
  - 左侧：应用图标位置（圆角矩形，100x100px）
  - 右侧：Applications图标位置
  - 中间：箭头引导
  - 底部：macsiwen logo + slogan
  - 右下角：二维码（小尺寸，100x100px）
```

## 故障排除

### 问题1：权限错误

```bash
chmod +x scripts/modify-dmg.sh
```

### 问题2：挂载失败

```bash
# 手动卸载所有挂载的卷
hdiutil info | grep "/dev/disk" | awk '{print $1}' | xargs -I {} hdiutil detach {}
```

### 问题3：找不到hdiutil

```bash
# hdiutil是macOS自带工具，如果找不到，请检查系统版本
which hdiutil
```

### 问题4：压缩时Segmentation Fault

如果在压缩步骤出现segfault，使用低压缩级别：

```bash
# 在脚本中修改压缩命令，添加 -imagekey zlib-level=1
hdiutil convert working.dmg -format UDZO -imagekey zlib-level=1 -o output.dmg
```

### 问题5：DMG打不开或损坏

```bash
# 验证DMG文件完整性
hdiutil verify output.dmg

# 如果损坏，重新生成
rm -rf temp/* output/*
./scripts/modify-dmg.sh "原始文件.dmg"
```

## 进阶用法

### 自定义替换规则

编辑 `scripts/modify-dmg.sh` 中的替换逻辑：

```bash
# 在步骤3中添加自定义替换
# 例如：替换特定文本文件
find "$mount_point" -name "*.txt" | while read txt_file; do
    sed -i '' 's/原品牌/macsiwen/g' "$txt_file"
done
```

## 更新日志

- **v1.0.0** (2025-12-21)
  - 初始版本
  - 支持单个文件和批量处理
  - 自动替换背景图、二维码、webloc文件
  - 自动修改DMG卷标名称
  - 使用低压缩级别避免segfault
  - 压缩率约60%，文件大小减少40%

## 技术支持

- 官网：https://macsiwen.com
- 问题反馈：提交Issue或联系管理员

---

**免责声明**：本工具仅供学习和个人使用，请勿用于商业用途或侵犯他人版权。
