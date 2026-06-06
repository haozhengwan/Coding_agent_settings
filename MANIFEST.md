# AI CLI 工具配置清单

## 项目信息

- **仓库**: haozhengwan/claude_code_settings
- **生成时间**: 2026-05-27
- **最后更新**: 2026-06-06
- **环境**: Linux (CentOS 8, x86_64) + GCC 14 + Python 3.13 + Rust 1.95
- **AI CLI 工具**: Claude Code (deepseek-v4-pro backend) + Gemini CLI + Codex CLI

## 文件清单

### 根目录

| 文件 | 说明 |
|------|------|
| README.md | 项目说明 + 一键部署指南 (Claude Code + Gemini CLI + Codex CLI) |
| restore.sh | **一键部署脚本** (Anaconda → Node.js → 3 个 AI CLI → API Key → 插件自动安装 → 配置恢复) |
| .env.example | API Key 配置模板 (Claude + Gemini + Codex, 可安全提交) |
| .gitignore | Git 忽略规则 (.env 已排除) |
| MANIFEST.md | 本文件 |

### 配置文件 (config/)

| 文件 | 说明 |
|------|------|
| settings.json | 全局设置 (7 插件, 4 marketplaces, dark theme, HUD) |
| keybindings.json | 键盘快捷键 (空, 使用默认) |

### 插件信息 (plugins/)

| 文件 | 说明 |
|------|------|
| installed_plugins.json | 7 个已安装插件及其版本 |
| known_marketplaces.json | 4 个 marketplaces 源地址 |

## restore.sh 部署流程

| 步骤 | 内容 |
|------|------|
| 1/9 | 系统环境检查 (OS, curl, wget, git) |
| 2/9 | Miniconda 安装 + conda 环境创建 (Python + Node.js) |
| 3/9 | Claude Code CLI 安装 (`npm install -g @anthropic-ai/claude-code`) |
| 4/9 | Gemini CLI 安装 (`npm install -g @google/gemini-cli`) |
| 5/9 | Codex CLI 安装 (`npm install -g @openai/codex`) |
| 6/9 | API Key 配置 (交互式创建 .env, 支持 Claude/Gemini/Codex 三种 key) |
| 7/9 | 环境变量加载与验证 (从 .env source 并校验) |
| 8/9 | Claude Code 插件自动安装 (marketplace add + plugin install, 7 个插件) |
| 9/9 | Claude Code 配置文件恢复 (settings.json + keybindings.json + marketplaces) |

## 可配置环境变量

### 基础环境

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CONDA_INSTALL_DIR` | `~/anaconda3` | conda 安装路径 |
| `CONDA_ENV_NAME` | `claude` | conda 环境名 |
| `NODE_VERSION` | `20` | Node.js 版本 |
| `PYTHON_VERSION` | `3.12` | Python 版本 |

### Claude Code (DeepSeek 代理)

| 变量 | 默认值 |
|------|--------|
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` |
| `ANTHROPIC_AUTH_TOKEN` | (需自行设置) |
| `ANTHROPIC_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` |

### Gemini CLI / Codex CLI

**默认使用浏览器 OAuth 登录，无需 API Key。**

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GEMINI_AUTH_METHOD` | `login` | Gemini 认证: `login` (浏览器OAuth) 或 `api_key` |
| `GEMINI_API_KEY` | (空) | Gemini API Key (仅 api_key 模式) |
| `CODEX_AUTH_METHOD` | `login` | Codex 认证: `login` (浏览器OAuth) 或 `api_key` |
| `OPENAI_API_KEY` | (空) | OpenAI API Key (仅 api_key 模式) |

## 已安装 Claude Code 插件 (7 个)

1. **superpowers@claude-plugins-official** (v5.1.0)
2. **code-review@claude-plugins-official**
3. **github@claude-plugins-official**
4. **skill-creator@claude-plugins-official**
5. **pua@pua-skills** (v3.4.6)
6. **oh-my-claudecode@omc** (v4.14.4)
7. **claude-hud@claude-hud** (v0.1.0)

> 插件通过 `claude plugin install` 命令行自动安装，无需手动操作。

## Marketplace 源

| 市场 | 源 | 类型 |
|------|-----|------|
| claude-plugins-official | anthropics/claude-plugins-official | github |
| pua-skills | tanweai/pua | github |
| omc | Yeachan-Heo/oh-my-claudecode | git |
| claude-hud | jarrodwatts/claude-hud | github |

## 启动命令

```bash
conda activate claude

# Claude Code
claude

# Gemini CLI
gemini

# Codex CLI
codex
```
