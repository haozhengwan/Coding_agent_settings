# Claude Code 配置清单

## 项目信息

- **仓库**: haozhengwan/claude_code_settings
- **生成时间**: 2026-05-27
- **环境**: Linux (CentOS 8, x86_64) + GCC 14 + Python 3.13 + Rust 1.95
- **Claude Code**: CLI mode, deepseek-v4-pro backend

## 文件清单

### 配置文件 (config/)

| 文件 | 说明 |
|------|------|
| settings.json | 全局设置 (7 插件, 3 自定义 marketplaces, dark theme) |
| keybindings.json | 键盘快捷键 (空, 使用默认) |

### 插件信息 (plugins/)

| 文件 | 说明 |
|------|------|
| installed_plugins.json | 7 个已安装插件及其版本 |
| known_marketplaces.json | 4 个 marketplaces 源地址 |

### 根目录

| 文件 | 说明 |
|------|------|
| README.md | 项目说明 + 快速恢复指南 |
| restore.sh | 一键恢复脚本 |
| .gitignore | Git 忽略规则 |
| MANIFEST.md | 本文件 |

## 已安装插件详情

1. **superpowers@claude-plugins-official** (v5.1.0, sha f2cbfbe)
2. **code-review@claude-plugins-official** (v unknown)
3. **github@claude-plugins-official** (v unknown)
4. **skill-creator@claude-plugins-official** (v unknown)
5. **pua@pua-skills** (v3.4.6, sha 56332fe)
6. **oh-my-claudecode@omc** (v4.14.4, sha 2733c16)
7. **claude-hud@claude-hud** (v0.1.0, sha be9902a)

## Marketplace 源

| 市场 | 源 | 类型 |
|------|-----|------|
| claude-plugins-official | anthropics/claude-plugins-official | github |
| pua-skills | tanweai/pua | github |
| omc | Yeachan-Heo/oh-my-claudecode | git |
| claude-hud | jarrodwatts/claude-hud | github |
