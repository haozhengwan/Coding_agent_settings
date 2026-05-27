# haozhengwan's Claude Code Settings

一键迁移 Claude Code 配置到任意设备。

## 快速恢复

```bash
git clone https://github.com/haozhengwan/claude_code_settings.git
cd claude_code_settings
bash restore.sh
```

## 目录结构

```
├── config/                    # 配置文件
│   ├── settings.json          # 全局设置 (插件, 权限, 主题)
│   └── keybindings.json       # 键盘快捷键
├── plugins/                   # 插件信息
│   ├── installed_plugins.json # 已安装插件列表
│   ├── known_marketplaces.json# 市场源地址
│   └── plugin-list.md         # 插件详细说明
├── memory/                    # 持久化记忆 (选填)
├── restore.sh                 # 一键恢复脚本
├── MANIFEST.md                # 完整文件清单
└── README.md                  # 本文件
```

## 已安装插件 (7 个)

| 插件 | 市场 | 版本 | 说明 |
|------|------|------|------|
| superpowers | claude-plugins-official | 5.1.0 | 系统化开发方法论 (TDD, brainstorming, code review 等) |
| code-review | claude-plugins-official | - | 代码审查 |
| github | claude-plugins-official | - | GitHub 集成 |
| skill-creator | claude-plugins-official | - | 创建自定义技能 |
| pua | pua-skills | 3.4.6 | PUA 高效工作流 |
| oh-my-claudecode | omc | 4.14.4 | 增强型工作流和工具集 (MCP, LSP) |
| claude-hud | claude-hud | 0.1.0 | 状态栏显示 |

## Marketplaces (4 个)

| 市场 | 来源 |
|------|------|
| claude-plugins-official | github:anthropics/claude-plugins-official |
| pua-skills | github:tanweai/pua |
| omc | git:Yeachan-Heo/oh-my-claudecode |
| claude-hud | github:jarrodwatts/claude-hud |

## 恢复步骤

1. Clone 本仓库
2. 运行 `bash restore.sh` 恢复配置文件
3. 启动 Claude Code — 会自动从配置的 marketplaces 拉取并安装插件
4. 如需手动安装：在 Claude Code 中 `/plugin install <name>@<marketplace>`

## 环境要求

- Claude Code CLI 已安装
- Git
- 网络连接 (用于拉取插件)
