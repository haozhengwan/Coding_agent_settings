# haozhengwan's AI CLI 工具一键部署

一键部署 Claude Code + Gemini CLI + Codex CLI 开发环境 + 配置恢复。

## 快速开始 (新机器)

```bash
git clone https://github.com/haozhengwan/claude_code_settings.git
cd claude_code_settings
bash restore.sh
```

脚本会按顺序完成:
1. **系统检查** — 安装 curl/wget/git 等基础工具
2. **Anaconda 安装** — Miniconda + 专用 conda 环境 (Python + Node.js)
3. **Claude Code CLI** — `npm install -g @anthropic-ai/claude-code`
4. **Gemini CLI** — `npm install -g @google/gemini-cli`
5. **Codex CLI** — `npm install -g @openai/codex`
6. **API Key 配置** — 交互式创建 `.env` 文件 (支持 Claude/Gemini/Codex 三种 key)
7. **环境变量加载** — 从 `.env` 加载并验证配置
8. **插件自动安装** — 命令行自动安装 7 个 Claude Code 插件
9. **配置恢复** — settings.json + keybindings.json + marketplaces

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

### 基础环境变量

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

### Claude Code 配置

```bash
# 使用自己的 DeepSeek API key
ANTHROPIC_AUTH_TOKEN=sk-your-deepseek-key bash restore.sh

# 或者使用其他 Anthropic 兼容 API
ANTHROPIC_BASE_URL=https://your-proxy.com/anthropic \
ANTHROPIC_AUTH_TOKEN=your-key \
ANTHROPIC_MODEL=your-model \
bash restore.sh
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` | Anthropic 兼容 API 地址 |
| `ANTHROPIC_AUTH_TOKEN` | (空) | API 认证 Token |
| `ANTHROPIC_MODEL` | `deepseek-v4-pro[1m]` | 默认模型 |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` | Opus 级别模型 |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` | Sonnet 级别模型 |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` | Haiku 级别模型 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` | Subagent 使用的模型 |

### Gemini CLI 配置

**默认使用浏览器 OAuth 登录，无需 API Key。** 首次运行 `gemini` 时会自动打开浏览器完成认证。

如需使用 API Key 方式：

```bash
GEMINI_AUTH_METHOD=api_key GEMINI_API_KEY=your-key bash restore.sh
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GEMINI_AUTH_METHOD` | `login` | 认证方式: `login` (浏览器OAuth) 或 `api_key` |
| `GEMINI_API_KEY` | (空) | Gemini API Key ([获取](https://aistudio.google.com/apikey)) |

### Codex CLI 配置

**默认使用浏览器 OAuth 登录，无需 API Key。** 首次运行 `codex` 时会自动打开浏览器完成认证。

如需使用 API Key 方式：

```bash
CODEX_AUTH_METHOD=api_key OPENAI_API_KEY=your-key bash restore.sh
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CODEX_AUTH_METHOD` | `login` | 认证方式: `login` (浏览器OAuth) 或 `api_key` |
| `OPENAI_API_KEY` | (空) | OpenAI API Key ([获取](https://platform.openai.com/api-keys)) |

### 一键设置所有 Key

```bash
ANTHROPIC_AUTH_TOKEN=sk-deepseek-xxx \
bash restore.sh
bash restore.sh
```

## .env.example 模板

运行脚本后会自动生成 `.env.example`，内容如下：

```bash
# ---- Claude Code (Anthropic 兼容 API) ----
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=your-deepseek-api-key-here
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash

# ---- Gemini CLI (默认浏览器 OAuth 登录, 无需 API Key) ----
GEMINI_AUTH_METHOD=login
# GEMINI_API_KEY=your-gemini-api-key-here

# ---- Codex CLI (默认浏览器 OAuth 登录, 无需 API Key) ----
CODEX_AUTH_METHOD=login
# OPENAI_API_KEY=your-openai-api-key-here
```

复制并填入真实 key：

```bash
cp .env.example .env
vim .env
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
```

### Claude Code

```bash
claude
```

插件已自动安装并加载，无需手动操作。如需重新加载插件：

```
/plugin reload
```

### Gemini CLI

```bash
gemini
```

### Codex CLI

```bash
codex
```

## 快速环境变量导入

如果 `.env` 已配置好，每次使用前快速加载：

```bash
source .env && conda activate claude
```

## 环境要求 (脚本会自动安装)

- Linux (x86_64/aarch64) 或 macOS
- 网络连接
- 脚本会自动安装: curl, wget, git, Miniconda, Node.js, Claude Code CLI, Gemini CLI, Codex CLI
