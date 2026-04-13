# DMG布局策略说明

## 🎯 核心策略

**全新自定义布局 + 保留原有功能**

### 什么会改变
- ✅ 窗口大小和位置
- ✅ 图标摆放位置
- ✅ 背景图
- ✅ 视图选项（图标大小、间距等）

### 什么会保留
- ✅ 所有原有文件（不删除任何文件）
- ✅ 安装教程视频（.rtfd文件）
- ✅ 修复软件损坏工具（exec文件）
- ✅ 说明文档
- ✅ 其他功能性文件

---

## 📋 工作原理

### .DS_Store的作用

`.DS_Store`文件只控制**视觉布局**，不影响文件本身：

```
.DS_Store 存储：
├── 窗口大小：1200×800
├── 图标位置：
│   ├── iShot.app: (100, 200)
│   ├── Applications: (500, 200)
│   ├── 安装教程.rtfd: (100, 400)
│   └── 修复工具: (500, 400)
├── 背景图路径：.background/background.png
├── 图标大小：128×128
└── 视图选项：网格间距、文本大小等
```

### 处理流程

```bash
原DMG
├── iShot.app                    # 保留 ✅
├── Applications (快捷方式)       # 保留 ✅
├── 安装教程视频.rtfd             # 保留 ✅
├── 修复软件损坏.exec             # 保留 ✅
├── .background/
│   └── old-bg.png              # 替换为 macsiwen 背景 ✅
└── .DS_Store                   # 替换为自定义布局 ✅

↓ 处理后

新DMG
├── iShot.app                    # 保留 ✅
├── Applications (快捷方式)       # 保留 ✅
├── 安装教程视频.rtfd             # 保留 ✅
├── 修复软件损坏.exec             # 保留 ✅
├── qrcode.jpg                   # 新增 macsiwen 二维码 ✅
├── 官网.webloc                  # 新增 macsiwen 官网 ✅
├── .background/
│   └── background.png          # macsiwen 背景 ✅
└── .DS_Store                   # 自定义布局 ✅
```

---

## 🎨 创建自定义布局步骤

### 第1步：准备参考DMG

选择一个原始DMG作为参考（如iShot.dmg），挂载它：

```bash
hdiutil attach iShot.dmg
```

查看它包含哪些文件：
- iShot.app
- Applications快捷方式
- 安装教程视频.rtfd
- 修复软件损坏工具
- 其他文档

### 第2步：创建模板DMG

```bash
cd tools/dmg-modifier/scripts
./create-template-dmg.sh
```

脚本会创建一个空白的可编辑DMG。

### 第3步：复制原DMG的所有文件

```bash
# 原DMG已挂载到 /Volumes/iShot
# 模板DMG已挂载到 /Volumes/macsiwen.com

# 复制所有文件（除了.DS_Store和.background）
cp -R /Volumes/iShot/iShot.app /Volumes/macsiwen.com/
cp -R /Volumes/iShot/Applications /Volumes/macsiwen.com/
cp -R /Volumes/iShot/安装教程视频.rtfd /Volumes/macsiwen.com/
cp /Volumes/iShot/修复软件损坏 /Volumes/macsiwen.com/
# ... 复制其他所有文件
```

**⚠️ 重要**：
- 不要复制 `.DS_Store`（我们要创建新的）
- 不要复制 `.background/`（我们有自己的背景图）

### 第4步：在Finder中设计布局

打开 `/Volumes/macsiwen.com`，按照你的想法摆放：

**推荐布局**（参考图片）：
```
┌─────────────────────────────────────────────────────┐
│  请仔细阅读以下安装教程 无法自行解决再拍照发客服询问  │
│                                                     │
│   [iShot.app]    ────→    [Applications]          │
│                                                     │
│                                                     │
│   [安装教程视频.rtfd]    [修复软件损坏]            │
│                                                     │
│   1.将箭头左边的应用程序拖动到右边的Applications... │
│   2.安装完毕后去启动台打开安装好的软件；            │
│   3.系统可能会提示 未知开发者、恶意软件、移到废纸篓等 │
│   ...                                               │
└─────────────────────────────────────────────────────┘
```

**关键点**：
1. 窗口大小：拖动右下角调整（建议1200×800）
2. 背景图：拖拽 `.background/background.png` 到背景栏
3. 图标位置：拖拽摆放所有元素
4. 视图选项：图标大小128×128，排列方式"无"

### 第5步：提取.DS_Store

```bash
./extract-ds-store.sh
```

这会把你设计的布局保存到 `templates/.DS_Store`

### 第6步：清理

```bash
# 卸载两个DMG
hdiutil detach /Volumes/iShot
hdiutil detach /Volumes/macsiwen.com

# 删除模板DMG（已提取.DS_Store）
rm ~/Desktop/macsiwen-template.dmg
```

---

## 🚀 批量应用

现在你有了自定义布局，可以批量处理：

```bash
./modify-dmg.sh "iShot Pro 2.5.8.dmg"
```

**处理过程**：
1. ✅ 转换为可读写格式
2. ✅ 挂载DMG
3. ✅ 修改卷标：macsiwen.com
4. ✅ 替换背景图：macsiwen背景
5. ✅ **应用自定义布局**：复制 `templates/.DS_Store`
6. ✅ 添加品牌文件：二维码、官网链接
7. ✅ **保留所有原有文件**：安装教程、修复工具等
8. ✅ 压缩打包

**结果**：
- 窗口大小和图标位置：按你的设计
- 背景图：macsiwen品牌
- 功能文件：全部保留
- 品牌信息：macsiwen二维码和官网

---

## 📊 对比

### 方案A：保留原布局（旧方案）
```
优点：
- 快速，不需要设计
- 保持原有视觉风格

缺点：
- 布局可能不适合macsiwen品牌
- 窗口大小可能不合适
- 图标位置可能混乱
```

### 方案B：全新自定义布局（当前方案）✅
```
优点：
- 完全控制视觉呈现
- 统一macsiwen品牌风格
- 优化用户体验
- 保留所有功能文件

缺点：
- 需要一次性设计布局
- 首次设置需要10分钟
```

---

## 🎯 最佳实践

### 1. 设计通用布局

设计一个适用于大多数软件的通用布局：

```
标准元素位置：
- 软件.app：左上 (100, 150)
- Applications：右上 (500, 150)
- 安装教程：左下 (100, 400)
- 修复工具：右下 (500, 400)
- 二维码：底部中间 (300, 550)
```

### 2. 处理特殊情况

如果某个DMG有额外文件：
- 手动调整该DMG的布局
- 提取新的.DS_Store
- 或者在通用布局基础上微调

### 3. 版本管理

```bash
# 保存不同版本的布局
cp templates/.DS_Store templates/.DS_Store.standard
cp templates/.DS_Store templates/.DS_Store.compact
cp templates/.DS_Store templates/.DS_Store.detailed

# 切换布局
cp templates/.DS_Store.standard templates/.DS_Store
```

---

## ⚠️ 注意事项

### 文件名匹配

.DS_Store中记录的是文件名，如果原DMG的文件名不同，可能需要调整：

```bash
# 例如：原DMG是 "iShot.app"，但你的模板是 "示例软件.app"
# 处理后图标位置可能不对

# 解决：在创建模板时，使用通用的文件名
# 或者为不同类型的软件创建不同的模板
```

### 背景图路径

.DS_Store中记录的背景图路径是相对路径：
```
.background/background.png
```

确保你的背景图文件名是 `background.png`，放在 `.background/` 目录下。

### 窗口大小

不同分辨率的屏幕，窗口大小可能需要调整：
- 标准屏幕：1200×800
- Retina屏幕：1440×900
- 小屏幕：1000×600

---

## 📚 参考

- [CUSTOM_LAYOUT_GUIDE.md](./CUSTOM_LAYOUT_GUIDE.md) - 详细操作指南
- [DMG_BRANDING_SOLUTION.md](./DMG_BRANDING_SOLUTION.md) - 技术方案
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - 快速参考

---

**版本**：v1.0.0  
**更新**：2025-12-23  
**策略**：全新布局 + 保留功能
