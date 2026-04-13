# dmg-macsiwen

从 `xianyu-toolbox` 独立拆分出的「DMG（Mac 软件品牌化工具）」首轮可运行版本。

## 目标

- 不改原项目代码
- 独立目录运行
- 先聚焦 DMG 品牌化能力（Electron + Shell 脚本）

## 已迁移的核心模块

- `electron/dmg-main.js`：主进程与 IPC（单文件/批量/设置/.DS_Store 模板）
- `electron/dmg-preload.js`：渲染层安全 API
- `electron/dmg-ui.html`：桌面 UI
- `electron/log-config.js`：日志配置
- `tools/dmg-modifier/`：DMG 处理脚本、模板、测试脚本
- `electron/assets/icons/` 与 `public/icon.*`：图标资源
- `electron-builder.json`：独立打包配置

## 快速运行

```bash
cd /Users/johnpeng/career_data/code/vcommerce-project/dmg-macsiwen
npm install
npm run dev
```

生产打包（mac）：

```bash
npm run build:mac
```

## 模板选择（新增）

当前桌面工具支持在 UI 中选择模板：

- `默认模板`：读取 `tools/dmg-modifier/templates/`
- `自定义模板`：读取 `tools/dmg-modifier/templates/profiles/<模板ID>/`

每个模板目录至少包含：

- `.DS_Store`（必需，决定 Finder 布局）
- `background.png` / `background.tiff`（建议）
- `*.webloc`、`qrcode.jpg`（按需）

## 打包说明（.DS_Store）

已修复打包时默认模板 `.DS_Store` 丢失问题。  
`electron-builder.json` 已显式包含：

- `tools/dmg-modifier/templates/.DS_Store`

如出现“默认模板缺少 .DS_Store”，请重新打包并验证产物内路径：

`DMG品牌化工具.app/Contents/Resources/tools/dmg-modifier/templates/.DS_Store`

## 原项目中已定位的 DMG 相关结构（梳理结论）

1. Electron 桌面主模块
- `electron/dmg-main.js`
- `electron/dmg-preload.js`
- `electron/dmg-ui.html`
- `electron/log-config.js`

2. DMG 核心处理工具链
- `tools/dmg-modifier/scripts/*.sh`
- `tools/dmg-modifier/templates/*`
- `tools/dmg-modifier/README.md`

3. Web 管理端（未纳入本次“首轮可运行”）
- `src/app/shop/admin/dmg-editor/page.tsx`
- `src/app/api/admin/dmg/*`
- `supabase/migrations/20251223_create_dmg_tasks.sql`
- `supabase/migrations/20251223_update_dmg_rls_strict.sql`

> 说明：本次新仓先保证 DMG 桌面工具独立可跑。Web 管理端与数据库链路可在下一轮按需接入。
