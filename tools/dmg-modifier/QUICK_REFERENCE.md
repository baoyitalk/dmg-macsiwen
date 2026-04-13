# DMG品牌化快速参考

## 🚀 快速开始

### Web界面（推荐）
```
1. 访问：http://localhost:3002/shop/admin/dmg-editor
2. 选择模板
3. 上传DMG文件
4. 点击"开始处理"
5. 下载处理后的文件
```

### 命令行
```bash
# 单个文件
cd tools/dmg-modifier
./scripts/modify-dmg.sh "xxx.dmg"

# 批量处理
./scripts/modify-dmg.sh --batch ~/Downloads/dmg-files
```

---

## 📋 三种方案对比

| 方案 | 工具 | 优点 | 缺点 | 适用场景 |
|-----|------|------|------|---------|
| **可视化** | DMG Canvas | 🎨 拖放操作<br>🎨 完全自定义布局<br>🎨 实时预览 | ❌ 需购买授权<br>❌ 无法批量处理 | 设计模板<br>精细化定制 |
| **命令行** | hdiutil + 脚本 | ✅ 完全免费<br>✅ 批量自动化<br>✅ 保留原布局 | 需要编写脚本 | 批量品牌化<br>自动化工作流 |
| **Web界面** | 我们的实现 | ✅ 无需命令行<br>✅ 批量处理<br>✅ 进度可视化 | 需要部署服务 | 日常使用<br>团队协作 |

---

## 🛠️ 核心技术

### hdiutil命令速查

```bash
# 转换为可读写格式
hdiutil convert input.dmg -format UDRW -o temp.dmg

# 挂载DMG
hdiutil attach temp.dmg -mountpoint /Volumes/MyDMG

# 卸载DMG
hdiutil detach /Volumes/MyDMG

# 压缩打包（低压缩，速度快）
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=1 -o output.dmg

# 压缩打包（高压缩，速度慢）
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o output.dmg
```

### diskutil命令速查

```bash
# 修改卷标名称
diskutil rename /Volumes/OldName "NewName"

# 查看磁盘信息
diskutil info /Volumes/MyDMG
```

---

## 📁 文件结构

```
tools/dmg-modifier/
├── scripts/
│   └── modify-dmg.sh          # 核心处理脚本
├── templates/                  # 品牌素材
│   ├── background.png         # 背景图（1440×900）
│   ├── qrcode.jpg            # 二维码
│   ├── 官网.webloc            # 官网链接
│   └── macsiwen.txt          # 品牌说明
├── output/                    # 处理后的DMG输出目录
└── temp/                      # 临时文件（自动清理）
```

---

## 🎨 自定义.DS_Store

### 方法1：DMG Canvas导出
1. 用DMG Canvas设计好布局
2. 导出.DS_Store文件
3. 放到 `templates/.DS_Store`
4. 脚本会自动使用

### 方法2：手动创建
```bash
# 1. 创建临时DMG
hdiutil create -volname "TempDMG" -size 500m -fs HFS+ -format UDRW ~/Desktop/TempDMG.dmg

# 2. 挂载并设置视图
hdiutil attach ~/Desktop/TempDMG.dmg
# 在Finder中：
# - 右键"显示视图选项"
# - 设置背景图、图标大小、排列方式
# - 摆放好元素

# 3. 显示隐藏文件
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# 4. 复制.DS_Store
cp /Volumes/TempDMG/.DS_Store ~/Desktop/templates/

# 5. 清理
hdiutil detach /Volumes/TempDMG
rm ~/Desktop/TempDMG.dmg
```

---

## ⚡ 性能优化

### 压缩级别选择
```bash
# 快速处理（60%压缩率，5秒）
zlib-level=1

# 平衡（70%压缩率，10秒）
zlib-level=5

# 最高压缩（80%压缩率，30秒）
zlib-level=9
```

### 批量处理建议
- 单次处理：≤10个文件
- 并发数：2-3个（避免磁盘IO瓶颈）
- 间隔时间：1秒/个

---

## 🔍 常见问题

### Q1: hdiutil: convert failed
**原因**：输入文件路径错误或文件损坏
**解决**：检查文件路径，确保DMG文件完整

### Q2: 处理后的DMG无法打开
**原因**：压缩级别过高导致segfault
**解决**：使用 `zlib-level=1` 低压缩

### Q3: 背景图没有替换
**原因**：原DMG没有.background目录
**解决**：需要自定义.DS_Store文件

### Q4: 卷标名称没有改变
**原因**：diskutil rename失败
**解决**：检查挂载点路径是否正确

---

## 🎯 最佳实践

### 1. 模板设计
- 背景图：1440×900 PNG格式
- 二维码：300×300 JPG格式
- 图标布局：参考Apple官方DMG

### 2. 批量处理
```bash
# 推荐流程
1. 准备素材 → templates/
2. 上传DMG → Web界面
3. 选择模板 → 批量处理
4. 下载结果 → output/
```

### 3. 质量检查
- ✅ 挂载DMG查看引导页面
- ✅ 测试App是否正常运行
- ✅ 检查文件大小是否合理
- ✅ 验证品牌信息是否正确

---

## 📚 相关文档

- [完整方案文档](./DMG_BRANDING_SOLUTION.md)
- [脚本使用说明](./README.md)
- [API文档](../../__pillars__/05-iteration/v1.1.54_DMG页面编辑功能.md)

---

**版本**：v1.0.0  
**更新**：2025-12-23
