# haozhengwan's AI CLI 工具一键部署

一键部署 Claude Code + Codex CLI 开发环境 + 配置恢复。

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
3. **Claude Code CLI** — 在所选环境中安装 `@anthropic-ai/claude-code`
4. **Codex CLI** — 在所选环境中安装 `@openai/codex`
5. **GitHub 认证** — git + gh CLI + SSH 配置
6. **API Key 配置** — 交互式创建 `.env` 文件 (支持 Claude/Codex 两种 key)
7. **环境变量加载** — 从 `.env` 加载并验证配置
8. **配置恢复** — settings.json + keybindings.json

## 目录结构

```
├── config/                    # 配置文件
│   ├── settings.json          # 全局设置 (主题)
│   └── keybindings.json       # 键盘快捷键
├── lib/network.sh            # 共享下载与 npm 重试函数
├── tests/test_network.py     # 离线网络故障回归检查
├── .env.example               # API Key 模板 (可安全提交)
├── .env                       # 你的真实 API Key (gitignore 已排除)
├── restore.sh                 # conda 版一键部署脚本
├── restore_uv.sh              # uv 版一键部署脚本 (轻量, 推荐容器使用)
├── MANIFEST.md                # 完整文件清单
├── .gitignore
└── README.md                  # 本文件
```

## 下载失败与代理配置

两个脚本在下载前读取 `.env`，网络设置也可作为环境变量传入。文件下载默认最多尝试 3 次，连接超时 15 秒，每次传输最长 600 秒。失败的临时文件会清理，只有完整且非空的下载才替换目标文件。npm 使用自身的重试机制并显示错误输出。

如本机已有 HTTP 代理，可设置实际端口后运行：

```bash
HTTPS_PROXY=http://127.0.0.1:7890 HTTP_PROXY=http://127.0.0.1:7890 bash restore_uv.sh
# conda 版同样支持
HTTPS_PROXY=http://127.0.0.1:7890 HTTP_PROXY=http://127.0.0.1:7890 bash restore.sh
```

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `DOWNLOAD_ATTEMPTS` | `3` | 每个文件的下载尝试次数 |
| `DOWNLOAD_CONNECT_TIMEOUT` | `15` | 每次连接超时（秒） |
| `DOWNLOAD_MAX_TIME` | `600` | 每次传输超时（秒） |
| `DOWNLOAD_RETRY_DELAY` | `2` | 文件下载重试间隔（秒） |
| `DOWNLOAD_IPV4` | `0` | 设为 `1` 强制文件下载使用 IPv4 |
| `NPM_REGISTRY` | npm 当前配置 | Claude Code / Codex npm 包下载源 |
| `NODE_DIST_URL` | `https://nodejs.org/dist` | uv 版 Node.js 下载根目录，需包含版本目录及校验清单 |
| `MINICONDA_BASE_URL` | `https://repo.anaconda.com/miniconda` | conda 安装器下载根目录 |
| `UV_INSTALLER_URL` | `https://astral.sh/uv/install.sh` | uv 安装脚本地址 |

下载源可改为你能访问的镜像；脚本不自动选择第三方镜像。`GITHUB_PROXY_URL` 仅用于 uv 版 gh Release 文件，失败后尝试官方地址，不代理 npm、Node.js 或 uv 安装器内部的下载。uv/Python 和 conda 包下载仍由各自工具处理，可使用通用 HTTP 代理及各自的源配置。文件重试参数不控制这些包管理器。

uv 版 Node.js 从下载源的完整清单选取版本并校验 SHA-256；查询、下载或校验失败时停止，不再使用旧的硬编码版本。校验用于检测文件损坏，镜像源本身应可信。

网络参数依据 [curl 文档](https://curl.se/docs/manpage.html) 和 [npm 配置文档](https://docs.npmjs.com/cli/v11/using-npm/config/)。

运行离线回归检查：

```bash
python3 -m unittest discover -s tests -v
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
| `GITHUB_PROXY_URL` / `GH_PROXY_URL` | (空) | GitHub 代理前缀, 如 `https://ghproxy.net`, 用于 uv 版 gh Release 下载 |

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

# ---- Codex CLI (默认浏览器 OAuth 登录, 无需 API Key) ----
CODEX_AUTH_METHOD=login
# OPENAI_API_KEY=your-openai-api-key-here
```

复制并填入真实 key：

```bash
cp .env.example .env
vim .env
```

## 安装范围

仅安装 Claude Code 和 Codex CLI，不安装插件、扩展或 marketplace。

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
codex      # Codex CLI
```

### uv 版

CLI 工具安装在 uv venv 的 `bin/` 目录内，激活 venv 后使用:

```bash
source ~/.venv/claude/bin/activate  # 或自定义的 VENV_DIR
claude     # Claude Code
codex      # Codex CLI
```

## 快速环境变量导入

如果 `.env` 已配置好，每次使用前快速加载：

```bash
# conda 版
set -a; source .env; set +a
conda activate claude

# uv 版
set -a; source .env; set +a
source ~/.venv/claude/bin/activate
```

## 环境要求 (脚本会自动安装)

### conda 版
- Linux (x86_64/aarch64) 或 macOS
- 网络连接
- 脚本会自动安装: curl, wget, git, Miniconda, Node.js, Claude Code CLI, Codex CLI

### uv 版
- Linux (x86_64/aarch64)
- 网络连接
- 脚本会自动安装: curl, wget, git, xz-utils, uv, Python venv, venv 内 Node.js, venv 内 Claude Code CLI, Codex CLI
