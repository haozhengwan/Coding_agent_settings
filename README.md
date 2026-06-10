# haozhengwan's AI CLI 工具一键部署

一键部署 Claude Code + Gemini CLI + Codex CLI 开发环境 + 配置恢复。

## 快速开始 (新机器)

提供两种环境管理方案，**功能等价，按需选用**:

| 方案 | 脚本 | 环境管理 | 体积 | 适用场景 |
|------|------|----------|------|----------|
| **conda 版** | `restore.sh` | Anaconda/Miniconda | ~500MB+ | 通用 Linux/macOS, 需要独立 Python + Node.js 环境 |
| **uv 版** | `restore_uv.sh` | uv + venv | ~20MB + Node.js | NVIDIA 容器, 已有系统 Python, 追求轻量且隔离 CLI |

### conda 版 (兼容性最广)

```bash
git clone https://github.com/haozhengwan/claude_code_settings.git
cd claude_code_settings
bash restore.sh
# 启动: conda activate claude
```

### uv 版 (轻量快速)

```bash
git clone https://github.com/haozhengwan/claude_code_settings.git
cd claude_code_settings
bash restore_uv.sh
# 激活 venv 后使用 CLI:
source ~/.venv/claude/bin/activate
```

### 部署流程 (两个版本)

脚本会按顺序完成:
1. **系统检查** — 安装 curl/wget/git 等基础工具
2. **环境安装** — conda (conda 版) 或 uv + venv + Node.js (uv 版, Node.js 位于 venv 内)
3. **Claude Code CLI** — 在 venv npm prefix 下安装 `@anthropic-ai/claude-code`
4. **Gemini CLI** — 在 venv npm prefix 下安装 `@google/gemini-cli`
5. **Codex CLI** — 在 venv npm prefix 下安装 `@openai/codex`
6. **GitHub 认证** — git + gh CLI + SSH 配置
7. **API Key 配置** — 交互式创建 `.env` 文件 (支持 Claude/Gemini/Codex 三种 key)
8. **环境变量加载** — 从 `.env` 加载并验证配置
9. **配置恢复** — settings.json + keybindings.json
10. **插件自动安装** — 命令行自动安装 7 个 Claude Code 插件

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
├── restore.sh                 # conda 版一键部署脚本
├── restore_uv.sh              # uv 版一键部署脚本 (轻量, 推荐容器使用)
├── MANIFEST.md                # 完整文件清单
├── .gitignore
└── README.md                  # 本文件
```

## 自定义变量

### uv 版专属变量 (`restore_uv.sh`)

```bash
# 自定义 venv 目录
VENV_DIR=~/.venv/claude-ai bash restore_uv.sh

# 自定义 Node.js / Python 版本
NODE_VERSION=22 PYTHON_VERSION=3.13 bash restore_uv.sh

# 自定义 Node.js / CLI 安装路径 (默认跟随 VENV_DIR, 通常无需设置)
NODE_INSTALL_PREFIX=~/.venv/claude bash restore_uv.sh

# GitHub 下载/克隆较慢时启用代理
GITHUB_PROXY_URL=https://ghproxy.net bash restore_uv.sh
# 或: GH_PROXY_URL=https://ghproxy.com bash restore_uv.sh
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VENV_DIR` | `~/.venv/claude` | Python 虚拟环境路径 |
| `NODE_VERSION` | `20` | Node.js 版本 (20 LTS) |
| `PYTHON_VERSION` | `3.12` | Python 版本 (uv 可自动下载) |
| `NODE_INSTALL_PREFIX` | `VENV_DIR` | Node.js 和 npm 全局 CLI 安装路径, 默认在 uv venv 内 |
| `GITHUB_PROXY_URL` / `GH_PROXY_URL` | (空) | GitHub 代理前缀, 如 `https://ghproxy.net`, 用于 uv 版 gh Release 下载、Gemini 扩展和 Claude marketplace 克隆 |

### conda 版专属变量 (`restore.sh`)

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

# ---- GitHub 认证 ----
GITHUB_TOKEN=your-github-token-here

# ---- GitHub 下载代理 (可选, uv 版) ----
# GITHUB_PROXY_URL=https://ghproxy.net

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

## 各 CLI 安装内容

脚本为三个 CLI **各自安装扩展/插件**，功能互不重叠:

---

### 🤖 Claude Code — 7 插件 + 4 市场 (脚本自动安装)

| 插件 | 市场 | 版本 | 说明 |
|------|------|------|------|
| **superpowers** | claude-plugins-official | 5.1.0 | 系统化开发方法论 (brainstorming → TDD → review → 收尾) |
| code-review | claude-plugins-official | - | 代码审查 |
| github | claude-plugins-official | - | GitHub 集成 (PR/Issue) |
| skill-creator | claude-plugins-official | - | 创建自定义技能 |
| pua | pua-skills | 3.4.6 | PUA 高效工作流 (13 种企业文化风格) |
| oh-my-claudecode | omc | 4.14.4 | 增强工具集 (30+ MCP 工具, 32+ Agent 类型) |
| claude-hud | claude-hud | 0.1.0 | 终端状态栏 (模型/token/session) |

**Marketplace 源:**

| 市场 | 来源 |
|------|------|
| claude-plugins-official | `anthropics/claude-plugins-official` |
| pua-skills | `tanweai/pua` |
| omc | `Yeachan-Heo/oh-my-claudecode` |
| claude-hud | `jarrodwatts/claude-hud` |

---

### 🔮 Gemini CLI — 1 扩展 (脚本自动安装)

| 扩展 | 来源 | 说明 |
|------|------|------|
| **superpowers** | `obra/superpowers` | 14 个开发工作流技能 (brainstorming, TDD, debugging, code review 等) |

```bash
# 手动安装命令 (脚本已自动执行)
gemini extensions install https://github.com/obra/superpowers
```

---

### ⚡ Codex CLI — 1 插件 (需手动安装)

| 插件 | 来源 | 说明 |
|------|------|------|
| **superpowers** | OpenAI 官方市场 | 14 个开发工作流技能 |

```bash
# 进入 Codex 交互界面后手动操作
codex
/plugins              # 打开插件搜索
# → 搜索 "superpowers" → 点击 Install
```

> ⚠️ Codex 插件必须通过交互界面安装，无法命令行自动化。
> Superpowers 项目: [github.com/obra/superpowers](https://github.com/obra/superpowers)

## 手动恢复 (仅配置文件)

如果已有 Claude Code 环境 (conda 或 uv 版均可)，只想恢复配置:

```bash
# 手动复制
cp config/settings.json ~/.claude/
cp config/keybindings.json ~/.claude/
```

## 启动

### conda 版

```bash
conda activate claude
claude     # Claude Code
gemini     # Gemini CLI
codex      # Codex CLI
```

### uv 版

CLI 工具安装在 uv venv 的 `bin/` 目录内，激活 venv 后使用:

```bash
source ~/.venv/claude/bin/activate  # 或自定义的 VENV_DIR
claude     # Claude Code
gemini     # Gemini CLI
codex      # Codex CLI
```

### 通用

插件已自动安装并加载，无需手动操作。如需重新加载插件：

```
/plugin reload
```

## 快速环境变量导入

如果 `.env` 已配置好，每次使用前快速加载：

```bash
# conda 版
source .env && conda activate claude

# uv 版
source .env && source ~/.venv/claude/bin/activate
```

## 环境要求 (脚本会自动安装)

### conda 版
- Linux (x86_64/aarch64) 或 macOS
- 网络连接
- 脚本会自动安装: curl, wget, git, Miniconda, Node.js, Claude Code CLI, Gemini CLI, Codex CLI

### uv 版
- Linux (x86_64/aarch64)
- 网络连接
- 脚本会自动安装: curl, wget, git, xz-utils, uv, Python venv, venv 内 Node.js, venv 内 Claude Code CLI, Gemini CLI, Codex CLI
