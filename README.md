# haozhengwan's Claude Code Settings

一键部署 Claude Code 开发环境 + 配置恢复。

## 快速开始 (新机器)

```bash
git clone https://github.com/haozhengwan/claude_code_settings.git
cd claude_code_settings
bash restore.sh
```

脚本会按顺序完成:
1. **系统检查** — 安装 curl/wget/git 等基础工具
2. **Anaconda 安装** — Miniconda + 专用 conda 环境 (Python + Node.js)
3. **Claude Code CLI** — 通过 npm 安装
4. **API Key 配置** — 交互式创建 `.env` 文件 (不提交到仓库)
5. **配置恢复** — settings.json + 插件 + marketplaces

## 目录结构

```
├── config/                    # 配置文件
│   ├── settings.json          # 全局设置 (插件, 权限, 主题)
│   └── keybindings.json       # 键盘快捷键
├── plugins/                   # 插件信息
│   ├── installed_plugins.json # 已安装插件列表
│   ├── known_marketplaces.json# 市场源地址
│   └── plugin-list.md         # 插件详细说明
├── .env.example               # API Key 模板 (可安全提交)
├── .env                       # 你的真实 API Key (gitignore 已排除)
├── restore.sh                 # 一键部署脚本
├── MANIFEST.md                # 完整文件清单
├── .gitignore
└── README.md                  # 本文件
```

## 自定义变量

运行脚本时可以覆盖默认值:

```bash
# 自定义 conda 安装路径
CONDA_INSTALL_DIR=/opt/anaconda3 bash restore.sh

# 自定义 conda 环境名 / Node 版本 / Python 版本
CONDA_ENV_NAME=myenv NODE_VERSION=22 PYTHON_VERSION=3.13 bash restore.sh
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CONDA_INSTALL_DIR` | `~/anaconda3` | conda 安装路径 |
| `CONDA_ENV_NAME` | `claude` | conda 环境名 |
| `NODE_VERSION` | `20` | Node.js 版本 |
| `PYTHON_VERSION` | `3.12` | Python 版本 |

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

## 手动恢复 (仅配置文件)

如果已有 conda + Claude Code 环境，只想恢复配置:

```bash
# 手动复制
cp config/settings.json ~/.claude/
cp config/keybindings.json ~/.claude/
mkdir -p ~/.claude/plugins
cp plugins/*.json ~/.claude/plugins/
```

## 启动

```bash
conda activate claude
claude
```

进入 Claude Code 后插件会自动从 marketplaces 拉取。也可手动安装:

```
/plugin install superpowers@claude-plugins-official
/plugin install code-review@claude-plugins-official
/plugin install github@claude-plugins-official
/plugin install skill-creator@claude-plugins-official
/plugin install pua@pua-skills
/plugin install oh-my-claudecode@omc
/plugin install claude-hud@claude-hud
/hud setup
```

## 环境要求 (脚本会自动安装)

- Linux (x86_64/aarch64) 或 macOS
- 网络连接
- 脚本会自动安装: curl, wget, git, Miniconda, Node.js, Claude Code CLI
