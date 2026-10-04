# AI 编程工具部署与配置

部署 Claude Code、Codex CLI 和 Antigravity CLI，并恢复 Claude Code 基础配置。默认使用 curl 下载官方原生安装器，**不需要 Anaconda、conda、uv、Python 或 Node.js 环境**。

本仓库使用 Antigravity CLI（`agy`），不再安装 Gemini CLI。不安装插件、编辑器扩展或 marketplace；`CLAUDE.md` 和 `GEMINI.md` 保持不存在。

## 快速开始

在 Linux/macOS 的 x64 或 ARM64 机器上，准备好 Bash、curl、tar，以及用于克隆仓库的 git：

```bash
git clone https://github.com/haozhengwan/Coding_agent_settings.git
cd Coding_agent_settings
bash restore.sh

# 让当前终端找到原生 CLI；建议同时加入 ~/.bashrc 或 ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
claude
codex
agy
```

默认流程：检查系统 → 安装 Claude Code → 安装 Codex CLI → 安装 Antigravity CLI → 恢复配置。已有命令会复用并检查版本；如果它来自已激活的 conda/venv，后续仍需激活对应环境。

脚本先完整下载安装器，下载成功后再执行。任何下载、安装或版本检查失败都会停止。原生模式覆盖 `~/.claude/settings.json` 和 `keybindings.json` 前，会将已有文件备份到该目录下的 `restore-backup.*`。可通过 `CLAUDE_CONFIG_DIR` 指定配置目录。

首次启动各 CLI 时按提示登录。原生模式不自动安装 gh 或修改 GitHub 认证；如有需要，自行安装 gh 后执行 `gh auth login`。

### 仅手动安装 CLI

以下命令来自 [Claude Code 官方文档](https://code.claude.com/docs/en/setup)、[Codex CLI 官方文档](https://learn.chatgpt.com/docs/codex/cli) 和 [Antigravity 官方文档](https://www.antigravity.google/docs/cli/install/)：

```bash
export CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --skip-aliases --skip-path
export PATH="$HOME/.local/bin:$PATH"
```

手动命令只安装 CLI，恢复本仓库配置的方法见下文。Antigravity 的 `--skip-aliases --skip-path` 保留现有 shell 别名及配置文件，PATH 由上面的命令设置。桌面版如有需要，可从 [Antigravity 下载页](https://antigravity.google/download) 单独安装。

## 可选的环境管理方式

| 方式 | 命令 | Claude Code / Codex 安装方式 | Antigravity 安装方式 |
|------|------|----------------------------|---------------------|
| 原生（默认） | `bash restore.sh` 或 `bash restore.sh --native` | 官方原生安装器 | 官方原生安装器，`~/.local/bin/agy` |
| conda（可选） | `bash restore.sh --conda` | conda 环境内 npm | 同上 |
| uv（可选，Linux） | `bash restore.sh --uv` | uv venv 内 Node.js + npm | 同上 |

也可直接执行 `bash restore_conda.sh` 或 `bash restore_uv.sh`。这两个方案保留原有的 GitHub 认证、API Key 交互配置和配置恢复流程；Claude 配置文件会直接覆盖，请按需先备份。仅在需要这些环境时选用。

```bash
# conda 版启动
conda activate claude
claude
codex

# uv 版启动
source ~/.venv/claude/bin/activate
claude
codex

# Antigravity 使用原生安装位置，三种方案相同
export PATH="$HOME/.local/bin:$PATH"
agy
```

### 环境变量

所有脚本都会在下载前加载仓库根目录的 `.env`。下列变量也可直接在命令前传入；同名设置以 `.env` 中的值为准。运行脚本仅在其子进程中加载变量，日常使用前仍需在当前终端加载 `.env`。

```bash
# 可选：使用已有的 Anthropic 兼容 API 配置
cp .env.example .env
vim .env
set -a; source .env; set +a
```

`.env.example` 保留现有的 DeepSeek 模型配置。按实际服务填写 `ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN` 和模型名称，再加载 `.env`；不要直接使用占位密钥。使用 CLI 的账号登录时不必复制模板。

Codex 默认按首次启动提示登录。如使用 API Key，在 `.env` 设置 `CODEX_AUTH_METHOD=api_key` 和 `OPENAI_API_KEY`，加载后按 [Codex 认证文档](https://learn.chatgpt.com/docs/auth) 完成登录。`CODEX_AUTH_METHOD` 只是本仓库的提示选项，脚本不会代为登录。

Antigravity 首次执行 `agy` 后按提示登录；SSH 场景按终端显示的授权链接和验证码完成登录，见 [官方认证说明](https://www.antigravity.google/docs/cli/install/)。

| 变量 | 默认值 | 适用范围 |
|------|--------|----------|
| `CLAUDE_INSTALLER_URL` | `https://claude.ai/install.sh` | 原生模式 |
| `CODEX_INSTALLER_URL` | `https://chatgpt.com/codex/install.sh` | 原生模式 |
| `ANTIGRAVITY_INSTALLER_URL` | `https://antigravity.google/cli/install.sh` | 所有模式 |
| `CLAUDE_CONFIG_DIR` | `~/.claude` | 原生模式配置恢复位置 |
| `CONDA_INSTALL_DIR` | `~/anaconda3` | conda 安装位置 |
| `CONDA_ENV_NAME` | `claude` | conda 环境名称 |
| `VENV_DIR` | `~/.venv/claude` | uv 虚拟环境 |
| `NODE_INSTALL_PREFIX` | `VENV_DIR` | uv 版 Node.js / npm CLI 位置 |
| `NODE_VERSION` | `20` | conda / uv 版 Node.js 版本 |
| `PYTHON_VERSION` | `3.12` | conda / uv 版 Python 版本 |

```bash
CONDA_ENV_NAME=myenv NODE_VERSION=22 bash restore.sh --conda
VENV_DIR=~/.venv/claude-ai NODE_VERSION=22 bash restore.sh --uv
```

## 下载失败与代理

```bash
HTTPS_PROXY=http://127.0.0.1:7890 HTTP_PROXY=http://127.0.0.1:7890 bash restore.sh
```

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `DOWNLOAD_ATTEMPTS` | `3` | 每个文件的下载尝试次数 |
| `DOWNLOAD_CONNECT_TIMEOUT` | `15` | 每次连接超时（秒） |
| `DOWNLOAD_MAX_TIME` | `600` | 每次传输超时（秒） |
| `DOWNLOAD_RETRY_DELAY` | `2` | 文件下载重试间隔（秒） |
| `DOWNLOAD_IPV4` | `0` | 设为 `1` 强制文件下载使用 IPv4 |
| `NPM_REGISTRY` | npm 当前配置 | conda / uv 版 npm 包下载源 |
| `NODE_DIST_URL` | `https://nodejs.org/dist` | uv 版 Node.js 下载根目录 |
| `MINICONDA_BASE_URL` | `https://repo.anaconda.com/miniconda` | conda 安装器下载根目录 |
| `UV_INSTALLER_URL` | `https://astral.sh/uv/install.sh` | uv 安装脚本地址 |
| `GITHUB_PROXY_URL` / `GH_PROXY_URL` | 空 | uv 版 gh Release 下载代理前缀 |

文件下载只有完整且非空时才替换目标，失败会清理临时文件。npm 使用自身的重试机制。uv 版 Node.js 从下载源的完整清单选取版本并校验 SHA-256，失败即停止。

`DOWNLOAD_*` 只控制本仓库直接下载的文件，不控制官方安装器内部下载及包管理器；这些步骤可使用通用 HTTP 代理和各工具自己的源配置。GitHub 下载代理仅用于 uv 版 gh Release，失败后尝试官方地址。自定义安装器地址会下载并执行代码，应指向可信来源；脚本不自动选择第三方镜像。

## 配置与仓库范围

`config/settings.json` 设置深色主题，并通过 `CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1` 关闭 Claude Code 官方插件市场的自动注册，含义见 [官方环境变量文档](https://code.claude.com/docs/en/env-vars)。仓库不包含插件安装、marketplace 恢复或 Gemini CLI 部署步骤；本地已有插件不在本次清理范围内。

本仓库不创建或恢复 `CLAUDE.md`、`GEMINI.md`。本地 `.omc/` 会话缓存已加入 gitignore，不参与部署。

仅恢复配置时，先按需备份原文件，再执行：

```bash
mkdir -p ~/.claude
cp config/settings.json config/keybindings.json ~/.claude/
```

## 目录结构

```text
├── restore.sh                # 默认原生安装；--conda / --uv 可选入口
├── restore_conda.sh          # 可选 conda 方案
├── restore_uv.sh             # 可选 uv + venv 方案
├── lib/
│   ├── network.sh            # 下载、代理与 npm 重试
│   └── installers.sh         # 官方安装器执行与 Antigravity 安装
├── config/
│   ├── settings.json         # Claude Code 主题与禁止自动注册插件市场
│   └── keybindings.json      # Claude Code 快捷键
├── tests/                    # 离线回归检查
├── .env.example              # 环境变量模板，真实 .env 已忽略
├── .gitignore
├── MANIFEST.md
└── README.md
```

## 验证

以下检查不会下载或安装软件：

```bash
for script in restore.sh restore_conda.sh restore_uv.sh lib/network.sh lib/installers.sh; do
  bash -n "$script" || break
done
python3 -m unittest discover -s tests -v
```
