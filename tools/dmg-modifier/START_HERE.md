# 🚀 从这里开始

## 目标

**复用原DMG的所有功能，只替换引导页面为macsiwen品牌**

---

## 📋 两步完成

### 第1步：创建自定义布局（只需做一次）

```bash
cd tools/dmg-modifier/scripts

# 使用一个参考DMG创建布局模板
./create-layout-from-reference.sh "iShot Pro 2.5.8.dmg"
```

**脚本会自动**：
1. ✅ 复制参考DMG的所有文件
2. ✅ 添加macsiwen品牌素材（背景图、二维码、官网链接）
3. ✅ 创建可编辑的模板DMG
4. ✅ 挂载到桌面

**然后你需要**：
1. 在Finder中打开挂载的DMG
2. 设计你想要的布局（拖拽摆放图标）
3. 运行 `./extract-ds-store.sh` 提取布局

**只需要做一次！** 之后所有DMG都用这个布局。

---

### 第2步：批量处理DMG

```bash
# 单个文件
./modify-dmg.sh "某个软件.dmg"

# 批量处理
./modify-dmg.sh --batch ~/Downloads/dmg-files
```

**每个DMG会**：
- ✅ 保留所有原有文件（安装教程、修复工具等）
- ✅ 应用你的自定义布局
- ✅ 替换为macsiwen背景图
- ✅ 添加macsiwen品牌元素

---

## 🎯 核心理念

```
原DMG                      处理后
├── 软件.app        →     ├── 软件.app         ✅ 保留
├── Applications    →     ├── Applications     ✅ 保留
├── 安装教程.rtfd    →     ├── 安装教程.rtfd     ✅ 保留
├── 修复工具        →     ├── 修复工具          ✅ 保留
├── 其他文件        →     ├── 其他文件          ✅ 保留
│                         ├── qrcode.jpg       ✅ 新增
│                         ├── 官网.webloc      ✅ 新增
├── .background/    →     ├── .background/
│   └── old-bg.png        │   └── background.png  ✅ 替换
└── .DS_Store       →     └── .DS_Store        ✅ 替换（你的布局）
```

---

## 📝 详细步骤

### 创建布局（第一次）

#### 1. 选择参考DMG
选择一个功能完整的DMG作为参考（如iShot.dmg）

#### 2. 运行创建脚本
```bash
./create-layout-from-reference.sh "iShot Pro 2.5.8.dmg"
```

#### 3. 设计布局
在Finder中打开 `/Volumes/macsiwen.com`：

**设置视图**（右键空白处 → 显示视图选项）：
- 图标大小：128×128
- 排列方式：无
- 网格间距：适中

**设置背景**：
- 背景：图片
- 拖拽 `.background/background.png` 到背景栏

**调整窗口**：
- 拖动右下角到合适大小（建议1200×800）

**摆放元素**：
```
┌─────────────────────────────────────────────────┐
│  请仔细阅读以下安装教程 无法自行解决再拍照发客服询问 │
│                                                 │
│   [软件.app]    ────→    [Applications]        │
│                                                 │
│   [安装教程.rtfd]        [修复工具]            │
│                                                 │
│   [qrcode.jpg]          [官网.webloc]         │
│                                                 │
│   1.将箭头左边的应用程序拖动到右边...            │
│   2.安装完毕后去启动台打开...                   │
└─────────────────────────────────────────────────┘
```

#### 4. 提取布局
```bash
./extract-ds-store.sh
```

输出：`templates/.DS_Store`

#### 5. 清理
```bash
hdiutil detach /Volumes/macsiwen.com
rm ~/Desktop/macsiwen-layout-template.dmg
```

---

### 批量处理（日常使用）

```bash
# 处理单个
./modify-dmg.sh "软件名.dmg"

# 批量处理
./modify-dmg.sh --batch ~/Downloads

# Web界面
# 访问 http://localhost:3002/shop/admin/dmg-editor
```

---

## 🎨 布局设计建议

### 窗口大小
- 标准：1200×800
- Retina：1440×900

### 元素摆放
```
上半部分：
- 左：软件.app
- 中：箭头（引导拖拽）
- 右：Applications快捷方式

下半部分：
- 左：安装教程视频
- 右：修复软件损坏工具

底部：
- 左：二维码
- 右：官网链接
- 中：说明文字
```

### 视觉原则
1. 对称美学
2. 视觉引导（App → 箭头 → Applications）
3. 信息层级（主要 > 次要 > 辅助）
4. 留白充足

---

## ⚡ 快速命令

```bash
# 创建布局（只做一次）
./create-layout-from-reference.sh "参考.dmg"
./extract-ds-store.sh

# 批量处理（日常使用）
./modify-dmg.sh --batch ~/Downloads

# 测试单个
./modify-dmg.sh "测试.dmg"
open output/测试-macsiwen.dmg
```

---

## 🆘 常见问题

### Q: 需要每个DMG都设计布局吗？
**A**: 不需要！只需要设计一次，之后所有DMG都用这个布局。

### Q: 原DMG的功能会丢失吗？
**A**: 不会！所有文件都保留，只是换了引导页面的布局和品牌。

### Q: 如果不同DMG文件名不一样怎么办？
**A**: 没关系，.DS_Store记录的是文件类型和位置，不是具体文件名。

### Q: 可以修改布局吗？
**A**: 可以！重新运行 `create-layout-from-reference.sh`，设计新布局，再提取。

---

## 📚 更多文档

- `LAYOUT_STRATEGY.md` - 布局策略详解
- `CUSTOM_LAYOUT_GUIDE.md` - 完整操作指南
- `QUICK_REFERENCE.md` - 命令速查表

---

**开始吧！** 🚀

```bash
cd tools/dmg-modifier/scripts
./create-layout-from-reference.sh "你的参考DMG.dmg"
```
