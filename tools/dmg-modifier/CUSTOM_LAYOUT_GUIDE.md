# 自定义DMG布局指南

## 🎯 目标

创建一个全新的、完全自定义的DMG引导页面布局，用于批量处理时应用。

---

## 📋 完整流程

### 第1步：创建可编辑的模板DMG

```bash
cd tools/dmg-modifier/scripts
./create-template-dmg.sh
```

**脚本会自动**：
- ✅ 创建500MB的可读写DMG
- ✅ 复制品牌素材（背景图、二维码、官网链接）
- ✅ 创建Applications快捷方式
- ✅ 创建示例App占位符
- ✅ 挂载到 `/Volumes/macsiwen.com`

**输出位置**：`~/Desktop/macsiwen-template.dmg`

---

### 第2步：在Finder中自定义布局

#### 2.1 打开DMG
```bash
# DMG已自动挂载到
open /Volumes/macsiwen.com
```

#### 2.2 设置视图选项
右键空白处 → **显示视图选项**

**推荐设置**：
```
图标大小: 128×128
网格间距: 适中
文本大小: 12
标签位置: 底部
排列方式: 无（重要！）
```

#### 2.3 设置背景图
在"视图选项"中：
1. 背景：选择"图片"
2. 拖拽 `.background/background.png` 到背景栏
3. 或点击"选择..."浏览选择

#### 2.4 调整窗口大小
拖动窗口右下角，建议尺寸：
- **标准**：1200×800
- **Retina**：1440×900

#### 2.5 摆放元素位置

**推荐布局**：
```
┌─────────────────────────────────────┐
│                                     │
│   [示例软件.app]    [Applications]  │
│                                     │
│                                     │
│   [qrcode.jpg]      [官网.webloc]  │
│                                     │
└─────────────────────────────────────┘
```

**拖拽调整**：
- 左侧：示例软件.app
- 右侧：Applications快捷方式
- 底部左：qrcode.jpg
- 底部右：官网.webloc

#### 2.6 添加拖拽箭头（可选）
如果需要添加"拖拽到Applications"的箭头：
1. 准备箭头图片（PNG，透明背景）
2. 复制到DMG中
3. 摆放在App和Applications之间

---

### 第3步：显示隐藏文件（查看.DS_Store）

```bash
# 显示隐藏文件
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# 重新打开DMG，确认.DS_Store文件存在
open /Volumes/macsiwen.com
```

你应该能看到：
- `.DS_Store` - 布局配置文件 ✅
- `.background/` - 背景图目录 ✅

---

### 第4步：提取.DS_Store文件

```bash
cd tools/dmg-modifier/scripts
./extract-ds-store.sh
```

**脚本会自动**：
- ✅ 检查DMG是否挂载
- ✅ 检查.DS_Store是否存在
- ✅ 备份旧的.DS_Store（如果有）
- ✅ 复制到 `templates/.DS_Store`

**输出位置**：`tools/dmg-modifier/templates/.DS_Store`

---

### 第5步：清理

```bash
# 卸载模板DMG
hdiutil detach /Volumes/macsiwen.com

# （可选）删除模板DMG
rm ~/Desktop/macsiwen-template.dmg

# 恢复隐藏文件设置
defaults write com.apple.finder AppleShowAllFiles -bool false
killall Finder
```

---

### 第6步：测试自定义布局

```bash
cd tools/dmg-modifier/scripts

# 处理一个测试DMG
./modify-dmg.sh "测试文件.dmg"

# 查看输出
open output/测试文件-macsiwen.dmg
```

**验证要点**：
- ✅ 窗口大小正确
- ✅ 背景图显示正确
- ✅ 图标位置符合预期
- ✅ 二维码和官网链接位置正确

---

## 🎨 布局设计建议

### 窗口尺寸
| 分辨率 | 窗口大小 | 适用场景 |
|--------|---------|---------|
| 标准 | 1200×800 | 通用 |
| Retina | 1440×900 | 高清屏 |
| 紧凑 | 1000×600 | 小屏幕 |

### 图标大小
| 类型 | 推荐大小 | 说明 |
|-----|---------|------|
| App图标 | 128×128 | 主要元素 |
| 二维码 | 96×96 | 次要元素 |
| 文本文件 | 64×64 | 辅助元素 |

### 配色方案
- **背景**：品牌色渐变（如蓝色渐变）
- **文字**：白色或深灰（高对比度）
- **图标**：保持原有颜色

### 布局原则
1. **对称美学**：左右平衡
2. **视觉引导**：App → 箭头 → Applications
3. **信息层级**：主要元素（App）> 次要元素（二维码）
4. **留白充足**：避免拥挤

---

## 🔧 高级技巧

### 自定义背景图

**推荐规格**：
- 格式：PNG（支持透明）
- 尺寸：1440×900（Retina）
- DPI：144（@2x）
- 文件大小：<500KB

**设计工具**：
- Figma / Sketch / Photoshop
- 在线工具：Canva

**设计要点**：
- 品牌色为主
- 渐变效果
- 避免过于花哨
- 确保图标可读性

### 添加自定义元素

**README文件**：
```bash
# 创建README
cat > /Volumes/macsiwen.com/README.txt << 'EOF'
欢迎使用 macsiwen.com 提供的软件！

安装步骤：
1. 将左侧App拖拽到右侧Applications文件夹
2. 打开Applications文件夹，找到并运行App
3. 首次运行可能需要在"系统偏好设置"中允许

更多软件请访问：macsiwen.com
扫描二维码关注公众号获取更多资源
EOF
```

**许可协议**：
```bash
# 添加许可协议（需要在打包时指定）
hdiutil create ... -license license.txt
```

---

## 📊 .DS_Store文件说明

### 文件作用
`.DS_Store`（Desktop Services Store）是macOS的隐藏文件，存储：
- 图标位置坐标
- 窗口大小和位置
- 背景图路径
- 图标大小
- 排列方式
- 视图选项

### 文件大小
- 正常：6-12 KB
- 复杂布局：12-24 KB
- 过大（>50KB）：可能包含缓存，需清理

### 兼容性
- ✅ macOS 10.6+
- ✅ 所有文件系统（HFS+, APFS）
- ✅ 跨版本兼容

---

## ⚠️ 常见问题

### Q1: .DS_Store文件不存在
**原因**：未在Finder中打开过DMG
**解决**：
1. 在Finder中打开DMG
2. 调整视图选项
3. 移动图标位置
4. 关闭窗口（自动保存.DS_Store）

### Q2: 布局没有生效
**原因**：.DS_Store路径不对或被覆盖
**解决**：
1. 确认 `templates/.DS_Store` 存在
2. 重新运行 `modify-dmg.sh`
3. 检查日志输出

### Q3: 背景图不显示
**原因**：背景图路径错误
**解决**：
1. 确保背景图在 `.background/` 目录
2. 文件名必须与.DS_Store中记录的一致
3. 通常命名为 `background.png`

### Q4: 窗口大小不对
**原因**：.DS_Store中的窗口尺寸与实际不符
**解决**：
1. 重新调整窗口大小
2. 重新提取.DS_Store

---

## 📚 参考资源

### 官方文档
- [hdiutil man page](https://ss64.com/osx/hdiutil.html)
- [Apple File System Guide](https://developer.apple.com/documentation/foundation/file_system)

### 设计参考
- Apple官方DMG（如Xcode、Safari）
- 知名软件DMG（如Sketch、Figma Desktop）

### 工具推荐
- **DMG Canvas**：可视化DMG设计工具
- **DS_Store Explorer**：查看.DS_Store内容
- **IconJar**：图标管理工具

---

## 🎯 最佳实践

### 设计流程
1. **草图设计** → 纸上或设计软件
2. **背景图制作** → Figma/Photoshop
3. **模板DMG创建** → `create-template-dmg.sh`
4. **Finder调整** → 拖拽摆放
5. **提取布局** → `extract-ds-store.sh`
6. **批量应用** → `modify-dmg.sh`

### 版本管理
```bash
# 备份不同版本的布局
cp templates/.DS_Store templates/.DS_Store.v1
cp templates/.DS_Store templates/.DS_Store.v2

# 切换布局
cp templates/.DS_Store.v1 templates/.DS_Store
```

### 团队协作
1. 设计师：设计背景图和布局
2. 开发者：创建模板DMG
3. 测试：验证布局效果
4. 运维：批量应用到生产

---

**文档版本**：v1.0.0  
**创建时间**：2025-12-23  
**作者**：macsiwen团队
