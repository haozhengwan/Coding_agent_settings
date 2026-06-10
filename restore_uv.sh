#!/bin/bash
# ============================================================
#  AI CLI 工具一键部署脚本 (uv 版 · 10 步)
#  涵盖: uv → venv → Node.js → Claude Code / Gemini CLI / Codex CLI → GitHub 认证 → API Key → 配置恢复 → 插件安装
#
#  适用场景: NVIDIA 官方容器 / 已有系统 Python 的环境
#  与 restore.sh (conda 版) 功能等价, 但使用 uv (20MB) 替代 Anaconda (500MB+)
#  两者互相独立, 按需选用
# ============================================================
set -eo pipefail

# ---- 可配置变量 ----
VENV_DIR="${VENV_DIR:-${HOME}/.venv/claude}"
NODE_VERSION="${NODE_VERSION:-20}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
NODE_INSTALL_PREFIX="${NODE_INSTALL_PREFIX:-}"
GITHUB_PROXY_URL="${GITHUB_PROXY_URL:-${GH_PROXY_URL:-}}"

# ---- Claude Code 配置 (可修改) ----
ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.deepseek.com/anthropic}"
ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-v4-flash}"
CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDE_CODE_SUBAGENT_MODEL:-deepseek-v4-flash}"

# ---- Gemini CLI 配置 (可修改) ----
# 认证方式: "login" (浏览器OAuth, 默认) 或 "api_key"
GEMINI_AUTH_METHOD="${GEMINI_AUTH_METHOD:-login}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"

# ---- Codex CLI 配置 (可修改) ----
# 认证方式: "login" (浏览器OAuth, 默认) 或 "api_key"
CODEX_AUTH_METHOD="${CODEX_AUTH_METHOD:-login}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---- 辅助函数 ----
step()  { echo -e "\n${BLUE}[${1}]${NC} ${2}"; }
ok()    { echo -e "  ${GREEN}✓${NC} ${1}"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} ${1}"; }
fail()  { echo -e "  ${RED}✗${NC} ${1}"; }
info()  { echo -e "  ${CYAN}→${NC} ${1}"; }

refresh_github_proxy_url() {
    if [ -z "${GITHUB_PROXY_URL:-}" ] && [ -n "${GH_PROXY_URL:-}" ]; then
        GITHUB_PROXY_URL="${GH_PROXY_URL}"
    fi
    if [ -n "${GITHUB_PROXY_URL:-}" ]; then
        GITHUB_PROXY_URL="${GITHUB_PROXY_URL%/}"
    fi
}

github_url() {
    local URL="$1"
    refresh_github_proxy_url

    if [ -n "${GITHUB_PROXY_URL:-}" ] && [[ "${URL}" == https://github.com/* ]]; then
        printf '%s/%s' "${GITHUB_PROXY_URL}" "${URL}"
    else
        printf '%s' "${URL}"
    fi
}

download_github_file() {
    local URL="$1"
    local OUTPUT="$2"
    local LABEL="${3:-GitHub 文件}"
    local DOWNLOAD_URL
    DOWNLOAD_URL="$(github_url "${URL}")"

    if [ "${DOWNLOAD_URL}" != "${URL}" ]; then
        info "通过 GitHub 代理下载 ${LABEL}..."
        if curl -fsSL "${DOWNLOAD_URL}" -o "${OUTPUT}"; then
            return 0
        fi
        warn "代理下载失败, 尝试直连 GitHub..."
    fi

    info "下载 ${LABEL}..."
    curl -fsSL "${URL}" -o "${OUTPUT}"
}

run_with_github_proxy() {
    refresh_github_proxy_url

    if [ -z "${GITHUB_PROXY_URL:-}" ]; then
        "$@"
    else
        GIT_CONFIG_COUNT=1 \
        GIT_CONFIG_KEY_0="url.${GITHUB_PROXY_URL}/https://github.com/.insteadOf" \
        GIT_CONFIG_VALUE_0="https://github.com/" \
        "$@"
    fi
}

configure_venv_toolchain() {
    if [ -z "${NODE_INSTALL_PREFIX:-}" ]; then
        NODE_INSTALL_PREFIX="${VENV_DIR}"
    fi
    NODE_INSTALL_PREFIX="${NODE_INSTALL_PREFIX%/}"
    mkdir -p "${NODE_INSTALL_PREFIX}/bin" "${NODE_INSTALL_PREFIX}/lib"
    export PATH="${NODE_INSTALL_PREFIX}/bin:${PATH}"
    export NPM_CONFIG_PREFIX="${NODE_INSTALL_PREFIX}"
}

npm_install_global() {
    local PACKAGE="$1"
    NPM_CONFIG_PREFIX="${NODE_INSTALL_PREFIX}" npm install -g "${PACKAGE}" > /dev/null 2>&1
}

banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   AI CLI 工具一键部署 (uv 版)          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Claude Code + Gemini CLI + Codex CLI  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

preload_env_vars() {
    if [ -f "${ENV_FILE}" ]; then
        info "预加载 ${ENV_FILE} ..."
        set -a
        source "${ENV_FILE}"
        set +a
        refresh_github_proxy_url
        ok ".env 已预加载"
    else
        refresh_github_proxy_url
    fi
}

# ---- 1. 系统环境检查 ----
check_system() {
    step "1/10" "系统环境检查"

    OS="$(uname -s)"
    ARCH="$(uname -m)"
    info "操作系统: ${OS} (${ARCH})"
    if [ -n "${GITHUB_PROXY_URL:-}" ]; then
        ok "GitHub 下载代理: ${GITHUB_PROXY_URL}"
        info "将用于 gh Release 下载、Gemini 扩展和 Claude marketplace 克隆"
    fi

    # 检查基础工具
    for cmd in curl wget tar; do
        if command -v $cmd &>/dev/null; then
            ok "$cmd 已就绪"
        else
            warn "$cmd 未安装, 尝试安装..."
            if command -v apt-get &>/dev/null; then
                apt-get update -qq && apt-get install -y -qq $cmd
            elif command -v yum &>/dev/null; then
                yum install -y -q $cmd
            elif command -v dnf &>/dev/null; then
                dnf install -y -q $cmd
            else
                warn "无法自动安装 $cmd, 请手动安装"
            fi
        fi
    done

    # 检查系统 Python (uv 需要)
    if command -v python3 &>/dev/null; then
        ok "python3: $(python3 --version 2>/dev/null)"
    elif command -v python &>/dev/null; then
        ok "python: $(python --version 2>/dev/null)"
    else
        warn "系统 Python 未找到, uv 将自动下载 Python ${PYTHON_VERSION}"
    fi

    # 检查 git (系统级, VS Code 等 IDE 需要)
    if [ -x "/usr/bin/git" ]; then
        ok "git 系统级: $(/usr/bin/git --version 2>/dev/null | awk '{print $NF}')"
    elif command -v git &>/dev/null; then
        warn "git 仅在非标准路径, 安装系统级 git (VS Code 需要)..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq git
            ok "git 系统级: $(/usr/bin/git --version 2>/dev/null | awk '{print $NF}')"
        elif command -v yum &>/dev/null; then
            yum install -y -q git
            ok "git 系统级: $(/usr/bin/git --version 2>/dev/null | awk '{print $NF}')"
        elif command -v dnf &>/dev/null; then
            dnf install -y -q git
            ok "git 系统级: $(/usr/bin/git --version 2>/dev/null | awk '{print $NF}')"
        else
            warn "无法自动安装系统级 git, 请手动安装"
        fi
    else
        warn "git 未安装, 尝试安装..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq git
        elif command -v yum &>/dev/null; then
            yum install -y -q git
        elif command -v dnf &>/dev/null; then
            dnf install -y -q git
        fi
        ok "git $(git --version 2>/dev/null | awk '{print $NF}')"
    fi

    # 检测是否需要 xz 解压工具 (Node.js tarball)
    if ! command -v xz &>/dev/null; then
        warn "xz 未安装, 尝试安装..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq xz-utils
        elif command -v yum &>/dev/null; then
            yum install -y -q xz
        elif command -v dnf &>/dev/null; then
            dnf install -y -q xz
        fi
    fi
}

# ---- 2a. uv 安装 ----
install_uv() {
    step "2/10" "uv + venv + Node.js 环境"

    info "--- uv Python 包管理器 ---"

    if command -v uv &>/dev/null; then
        ok "uv 已安装: $(uv --version 2>/dev/null)"
        UV_EXISTING="yes"
    elif [ -f "${HOME}/.local/bin/uv" ]; then
        ok "uv 已存在于 ~/.local/bin"
        export PATH="${HOME}/.local/bin:${PATH}"
        UV_EXISTING="yes"
    elif [ -f "${HOME}/.cargo/bin/uv" ]; then
        ok "uv 已存在于 ~/.cargo/bin"
        export PATH="${HOME}/.cargo/bin:${PATH}"
        UV_EXISTING="yes"
    else
        UV_EXISTING="no"
    fi

    if [ "${UV_EXISTING}" = "no" ]; then
        info "安装 uv (Astral 官方脚本)..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="${HOME}/.local/bin:${PATH}"
        ok "uv 安装完成: $(uv --version 2>/dev/null)"
    fi

    # 确保 uv 在 PATH 中
    if ! command -v uv &>/dev/null; then
        export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
    fi
}

# ---- 2b. venv 创建 ----
setup_venv() {
    info "--- Python 虚拟环境 ---"

    # 检测系统是否有合适的 Python
    local PYTHON_CMD=""
    if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
    fi

    # 检查 Python 版本是否满足要求
    local PY_OK=false
    if [ -n "${PYTHON_CMD}" ]; then
        local PY_VER
        PY_VER=$("${PYTHON_CMD}" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0")
        local REQ_MAJOR="${PYTHON_VERSION%%.*}"
        local REQ_MINOR="${PYTHON_VERSION#*.}"
        local SYS_MAJOR="${PY_VER%%.*}"
        local SYS_MINOR="${PY_VER#*.}"
        if [ "${SYS_MAJOR}" -ge "${REQ_MAJOR}" ] && [ "${SYS_MINOR}" -ge "${REQ_MINOR}" ]; then
            PY_OK=true
            ok "系统 Python ${PY_VER} 满足要求 (>= ${PYTHON_VERSION})"
        else
            warn "系统 Python ${PY_VER} 不满足要求 (>= ${PYTHON_VERSION}), uv 将自动下载"
        fi
    fi

    if [ -d "${VENV_DIR}" ] && [ -f "${VENV_DIR}/bin/python" ]; then
        ok "venv 已存在: ${VENV_DIR}"
        # 验证 Python 版本
        local VENV_PY_VER
        VENV_PY_VER=$("${VENV_DIR}/bin/python" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0")
        ok "  venv Python: ${VENV_PY_VER}"
    else
        info "创建 venv: ${VENV_DIR} (Python ${PYTHON_VERSION})..."
        if [ "${PY_OK}" = true ]; then
            # 使用系统 Python
            uv venv "${VENV_DIR}" --python "${PYTHON_CMD}"
        else
            # uv 自动下载指定版本的 Python
            uv venv "${VENV_DIR}" --python "${PYTHON_VERSION}"
        fi
        ok "venv 创建完成"
    fi

    # 升级 pip (在 venv 内)
    if [ -f "${VENV_DIR}/bin/pip" ]; then
        "${VENV_DIR}/bin/pip" install --upgrade pip -q 2>/dev/null || true
    fi
}

# ---- 2c. Node.js 安装 ----
install_nodejs() {
    info "--- Node.js 运行时 ---"
    configure_venv_toolchain

    # uv 版将 Node.js 放入 venv, 不复用系统 Node.js
    local NODE_BIN="${NODE_INSTALL_PREFIX}/bin/node"
    local NPM_BIN="${NODE_INSTALL_PREFIX}/bin/npm"
    if [ -x "${NODE_BIN}" ]; then
        local NODE_VER
        NODE_VER=$("${NODE_BIN}" --version 2>/dev/null | sed 's/^v//')
        local NODE_MAJOR="${NODE_VER%%.*}"
        if [ "${NODE_MAJOR}" -ge "${NODE_VERSION}" ]; then
            ok "venv Node.js ${NODE_VER} 已满足要求 (>= ${NODE_VERSION})"
            ok "npm $("${NPM_BIN}" --version 2>/dev/null)"
            return
        else
            warn "venv Node.js ${NODE_VER} 版本过低, 将安装 ${NODE_VERSION}.x"
        fi
    fi

    # 确定平台对应的 Node.js 下载 URL
    local NODE_DISTRO="linux"
    local NODE_ARCH="x64"
    case "${ARCH}" in
        x86_64|amd64) NODE_ARCH="x64" ;;
        aarch64|arm64) NODE_ARCH="arm64" ;;
        armv7l)        NODE_ARCH="armv7l" ;;
        *)             fail "不支持的 CPU 架构: ${ARCH}"; return 1 ;;
    esac

    # 获取 Node.js 最新 LTS 版本号 (通过 nodejs.org API)
    local NODE_FULL_VERSION
    info "查询 Node.js ${NODE_VERSION}.x 最新版本..."
    NODE_FULL_VERSION=$(curl -fsSL "https://nodejs.org/dist/latest-v${NODE_VERSION}.x/SHASUMS256.txt" 2>/dev/null | head -1 | awk '{print $2}' | sed 's/node-v//;s/-.*//' || echo "")

    if [ -z "${NODE_FULL_VERSION}" ]; then
        # 回退: 使用已知的稳定版本号
        case "${NODE_VERSION}" in
            18) NODE_FULL_VERSION="18.20.4" ;;
            20) NODE_FULL_VERSION="20.15.1" ;;
            22) NODE_FULL_VERSION="22.12.0" ;;
            24) NODE_FULL_VERSION="24.2.0" ;;
            *)  NODE_FULL_VERSION="${NODE_VERSION}.0.0" ;;
        esac
        warn "无法查询最新版本, 使用 ${NODE_FULL_VERSION}"
    fi
    info "Node.js 版本: v${NODE_FULL_VERSION}"

    local NODE_URL="https://nodejs.org/dist/v${NODE_FULL_VERSION}/node-v${NODE_FULL_VERSION}-${NODE_DISTRO}-${NODE_ARCH}.tar.xz"
    local NODE_TARBALL="/tmp/node-v${NODE_FULL_VERSION}.tar.xz"

    info "下载 ${NODE_URL} ..."
    if curl -fsSL "${NODE_URL}" -o "${NODE_TARBALL}"; then
        ok "下载完成"

        info "解压到 ${NODE_INSTALL_PREFIX} ..."
        tar -xJf "${NODE_TARBALL}" -C "${NODE_INSTALL_PREFIX}" --strip-components=1
        rm -f "${NODE_TARBALL}"
        configure_venv_toolchain

        ok "Node.js $("${NODE_BIN}" --version 2>/dev/null)"
        ok "npm $("${NPM_BIN}" --version 2>/dev/null)"
        ok "Node.js 已安装到 venv: ${NODE_INSTALL_PREFIX}"
    else
        fail "Node.js 下载失败, 请检查网络"
        warn "你可以手动安装 Node.js 后重新运行本脚本"
    fi
}

# ---- 3. Claude Code CLI 安装 ----
install_claude_code() {
    step "3/10" "Claude Code CLI 安装"
    configure_venv_toolchain
    local CLAUDE_BIN="${NODE_INSTALL_PREFIX}/bin/claude"

    if [ -x "${CLAUDE_BIN}" ]; then
        ok "claude 已安装: $("${CLAUDE_BIN}" --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 venv npm 安装 @anthropic-ai/claude-code ..."
        npm_install_global @anthropic-ai/claude-code
        ok "Claude Code CLI 安装完成"
    fi

    # 确认
    CLAUDE_PATH="${CLAUDE_BIN}"
    if [ -x "${CLAUDE_PATH}" ]; then
        ok "claude 路径: ${CLAUDE_PATH}"
    else
        warn "未能检测到 claude 命令, 可能需要重启终端或手动加入 PATH"
    fi
}

# ---- 4. Gemini CLI 安装 ----
install_gemini_cli() {
    step "4/10" "Gemini CLI 安装"
    configure_venv_toolchain
    local GEMINI_BIN="${NODE_INSTALL_PREFIX}/bin/gemini"

    if [ -x "${GEMINI_BIN}" ]; then
        ok "gemini 已安装: $("${GEMINI_BIN}" --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 venv npm 安装 @google/gemini-cli ..."
        npm_install_global @google/gemini-cli
        ok "Gemini CLI 安装完成"
    fi

    GEMINI_PATH="${GEMINI_BIN}"
    if [ -x "${GEMINI_PATH}" ]; then
        ok "gemini 路径: ${GEMINI_PATH}"
    else
        warn "未能检测到 gemini 命令, 可能需要重启终端或手动加入 PATH"
    fi

    # 安装 Superpowers 扩展
    info "安装 Superpowers 扩展..."
    if [ -n "${GITHUB_PROXY_URL:-}" ]; then
        info "Superpowers GitHub 克隆使用代理: ${GITHUB_PROXY_URL}"
    fi
    if (yes || true) | run_with_github_proxy "${GEMINI_BIN}" extensions install https://github.com/obra/superpowers 2>&1 | tail -1; then
        ok "Gemini Superpowers 安装完成"
    else
        warn "Gemini Superpowers 安装失败 (可稍后手动: gemini extensions install https://github.com/obra/superpowers)"
    fi
}

# ---- 5. Codex CLI 安装 ----
install_codex_cli() {
    step "5/10" "Codex CLI 安装"
    configure_venv_toolchain
    local CODEX_BIN="${NODE_INSTALL_PREFIX}/bin/codex"

    if [ -x "${CODEX_BIN}" ]; then
        ok "codex 已安装: $("${CODEX_BIN}" --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 venv npm 安装 @openai/codex ..."
        npm_install_global @openai/codex
        ok "Codex CLI 安装完成"
    fi

    CODEX_PATH="${CODEX_BIN}"
    if [ -x "${CODEX_PATH}" ]; then
        ok "codex 路径: ${CODEX_PATH}"
    else
        warn "未能检测到 codex 命令, 可能需要重启终端或手动加入 PATH"
    fi
}

# ---- 6. GitHub 认证配置 ----
setup_github_auth() {
    step "6/10" "GitHub 认证配置 (git + gh CLI + SSH)"
    configure_venv_toolchain
    local GH_BIN="${NODE_INSTALL_PREFIX}/bin/gh"

    # 修复 git 安全目录问题 (常见于 root/sudo 场景)
    info "配置 git 安全目录..."
    git config --global --add safe.directory "$(pwd)" 2>/dev/null || true
    git config --global --add safe.directory "${HOME}" 2>/dev/null || true
    ok "git safe.directory 已配置"

    # 安装 GitHub CLI (直接下载二进制, 不依赖 conda)
    if [ -x "${GH_BIN}" ]; then
        ok "gh CLI 已安装: $("${GH_BIN}" --version 2>/dev/null | head -1)"
    else
        info "安装 GitHub CLI (gh)..."
        local GH_INSTALLED=false

        # 尝试方式 1: 从 GitHub releases 下载预编译二进制
        local GH_VERSION="2.68.1"
        local GH_ARCH="amd64"
        case "${ARCH}" in
            aarch64|arm64) GH_ARCH="arm64" ;;
        esac

        if [ "${OS}" = "Linux" ]; then
            local GH_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz"
            local GH_TARBALL="/tmp/gh.tar.gz"
            local GH_TMPDIR="/tmp/gh_extract"

            if download_github_file "${GH_URL}" "${GH_TARBALL}" "gh CLI ${GH_VERSION}"; then
                mkdir -p "${GH_TMPDIR}"
                tar -xzf "${GH_TARBALL}" -C "${GH_TMPDIR}" --strip-components=1

                mkdir -p "${NODE_INSTALL_PREFIX}/bin"
                cp "${GH_TMPDIR}/bin/gh" "${GH_BIN}"
                chmod +x "${GH_BIN}"
                configure_venv_toolchain
                rm -rf "${GH_TARBALL}" "${GH_TMPDIR}"
                GH_INSTALLED=true
                ok "gh CLI 安装完成: $("${GH_BIN}" --version 2>/dev/null | head -1)"
            fi
        fi

        # 尝试方式 2: npm 安装
        if [ "${GH_INSTALLED}" = false ]; then
            info "尝试通过 venv npm 安装 gh..."
            if npm_install_global @github/gh; then
                GH_INSTALLED=true
                ok "gh CLI (npm) 安装完成"
            fi
        fi

        if [ "${GH_INSTALLED}" = false ]; then
            warn "gh CLI 安装失败, 请手动安装到 ${NODE_INSTALL_PREFIX}/bin/gh: https://github.com/cli/cli/releases"
        fi
    fi

    # 配置 SSH: 添加 GitHub host key
    info "配置 GitHub SSH host key..."
    mkdir -p "${HOME}/.ssh"
    if ! grep -q "github.com" "${HOME}/.ssh/known_hosts" 2>/dev/null; then
        ssh-keyscan github.com >> "${HOME}/.ssh/known_hosts" 2>/dev/null
        ok "GitHub SSH host key 已添加"
    else
        ok "GitHub SSH host key 已存在"
    fi

    # 检测认证状态
    local AUTH_OK=false
    local USE_TOKEN=false

    # 方式 1: 环境变量 GITHUB_TOKEN / GH_TOKEN (优先, 无需交互)
    if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "your-github-token-here" ]; then
        info "检测到 GITHUB_TOKEN, 配置 gh CLI..."
        export GH_TOKEN="${GITHUB_TOKEN}"
        if [ -x "${GH_BIN}" ] && echo "${GITHUB_TOKEN}" | "${GH_BIN}" auth login --with-token 2>/dev/null; then
            ok "GitHub 已通过 GITHUB_TOKEN 认证"
            USE_TOKEN=true
            AUTH_OK=true
        else
            warn "gh auth login --with-token 失败"
        fi

        # 配置 git 使用 token 进行 HTTPS 认证
        info "配置 git credential (HTTPS)..."
        git config --global credential.helper store 2>/dev/null || true
        git config --global url."https://oauth2:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/" 2>/dev/null || true
        ok "git HTTPS credential 已配置"
    elif [ -n "${GH_TOKEN}" ] && [ "${GH_TOKEN}" != "your-github-token-here" ]; then
        export GITHUB_TOKEN="${GH_TOKEN}"
        if [ -x "${GH_BIN}" ] && echo "${GH_TOKEN}" | "${GH_BIN}" auth login --with-token 2>/dev/null; then
            ok "GitHub 已通过 GH_TOKEN 认证"
            USE_TOKEN=true
            AUTH_OK=true
            git config --global url."https://oauth2:${GH_TOKEN}@github.com/".insteadOf "https://github.com/" 2>/dev/null || true
        fi
    fi

    # 方式 2: gh CLI 已有认证
    if [ "${AUTH_OK}" = false ]; then
        if [ -x "${GH_BIN}" ] && "${GH_BIN}" auth status 2>&1 | grep -q "Logged in"; then
            ok "GitHub 已通过 gh CLI 认证"
            AUTH_OK=true
        fi
    fi

    # 方式 3: SSH 认证
    if [ "${AUTH_OK}" = false ]; then
        info "检测 SSH 认证..."
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -qE "successfully authenticated|You've successfully authenticated"; then
            ok "GitHub SSH 认证成功"
            AUTH_OK=true
        fi
    fi

    # 未认证时引导
    if [ "${AUTH_OK}" = false ]; then
        warn "GitHub 未认证"

        echo ""
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${YELLOW}  GitHub 认证设置${NC}"
        echo ""
        echo -e "  选择一种方式完成认证:"
        echo ""
        echo -e "  ${CYAN}方式一 (推荐): gh CLI 浏览器 OAuth 登录${NC}"
        echo -e "    gh auth login"
        echo ""
        echo -e "  ${CYAN}方式二: 设置 GITHUB_TOKEN 环境变量${NC}"
        echo -e "    export GITHUB_TOKEN='your-personal-access-token'"
        echo -e "    生成: https://github.com/settings/tokens"
        echo ""
        echo -e "  ${CYAN}方式三: 配置 SSH Key${NC}"
        echo -e "    ssh-keygen -t ed25519 -C \"your@email.com\""
        echo -e "    cat ~/.ssh/id_ed25519.pub  # 添加到 https://github.com/settings/keys"
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 交互式询问 (非交互环境自动跳过)
        read -r -p "  是否已经准备好认证? (y/n, 选 n 跳过): " AUTH_READY 2>/dev/null || AUTH_READY="n"
        if [ "${AUTH_READY}" = "y" ] || [ "${AUTH_READY}" = "Y" ]; then
            info "尝试 gh auth login..."
            "${GH_BIN}" auth login || {
                warn "gh auth login 失败, 请稍后手动认证"
            }
        else
            info "跳过 GitHub 认证 (插件安装步骤仍会使用 HTTPS 克隆公开仓库)"
        fi
    fi

    ok "GitHub 认证配置完成"
}

# ---- 7. API Key 配置 ----
setup_api_key() {
    step "7/10" "API Key 配置 (Claude + Gemini + Codex + GitHub)"

    if [ ! -f "${ENV_EXAMPLE}" ]; then
        info "创建 .env.example 模板..."
        cat > "${ENV_EXAMPLE}" << 'EOF'
# ============================================
#  AI CLI 工具 API Key 配置文件
#  复制此文件为 .env 并填入你的真实密钥
#  cp .env.example .env
# ============================================

# ---- Claude Code (Anthropic 兼容 API) ----
# 使用第三方 API 代理 (如 DeepSeek)
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=your-deepseek-api-key-here
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash

# ---- GitHub 认证 ----
# 用于 gh CLI 认证 + git push/pull (无需浏览器 OAuth)
# 生成: https://github.com/settings/tokens → Generate new token (classic)
# 权限: repo, workflow (根据需要勾选)
GITHUB_TOKEN=your-github-token-here

# ---- GitHub 下载代理 (可选) ----
# 国内访问 GitHub 慢时可启用, 如 https://ghproxy.net 或 https://ghproxy.com
# uv 版会用于 gh Release 下载、Gemini 扩展和 Claude marketplace 克隆
# GITHUB_PROXY_URL=https://ghproxy.net

# ---- Gemini CLI ----
# 认证方式: "login" (浏览器OAuth登录) 或 "api_key"
GEMINI_AUTH_METHOD=login
# 如果使用 api_key 方式, 取消下面这行的注释并填入 key
# 获取: https://aistudio.google.com/apikey
# GEMINI_API_KEY=your-gemini-api-key-here

# ---- Codex CLI (OpenAI) ----
# 认证方式: "login" (浏览器OAuth登录) 或 "api_key"
CODEX_AUTH_METHOD=login
# 如果使用 api_key 方式, 取消下面这行的注释并填入 key
# 获取: https://platform.openai.com/api-keys
# OPENAI_API_KEY=your-openai-api-key-here
EOF
        ok ".env.example 模板已创建"
    else
        ok ".env.example 已存在"
    fi

    if [ -f "${ENV_FILE}" ]; then
        ok ".env 文件已存在 (你的 API key 已配置)"
        # 检查是否还是占位符
        if grep -q "your-deepseek-api-key-here" "${ENV_FILE}" 2>/dev/null; then
            warn "检测到 .env 中仍是占位符, 请编辑填入真实 key:"
            warn "   vim ${ENV_FILE}"
        fi
    else
        warn ".env 文件不存在"

        echo ""
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${YELLOW}  API Key 设置说明${NC}"
        echo ""
        echo -e "  方式一 (推荐): 使用 .env 文件"
        echo -e "    cp .env.example .env"
        echo -e "    vim .env  # 填入你的真实 API key"
        echo ""
        echo -e "  方式二: 设置环境变量"
        echo -e "    export ANTHROPIC_AUTH_TOKEN='your-deepseek-key'"
        echo ""
        echo -e "  ${CYAN}▸ Gemini / Codex 默认使用浏览器 OAuth 登录, 无需 API Key${NC}"
        echo -e "  如需 API Key 方式, 在 .env 中设置:"
        echo -e "    GEMINI_AUTH_METHOD=api_key"
        echo -e "    GEMINI_API_KEY=your-gemini-key"
        echo -e "    CODEX_AUTH_METHOD=api_key"
        echo -e "    OPENAI_API_KEY=your-openai-key"
        echo ""
        echo -e "  获取 API Key:"
        echo -e "    DeepSeek:  ${CYAN}https://platform.deepseek.com/api_keys${NC}"
        echo -e "    Gemini:    ${CYAN}https://aistudio.google.com/apikey${NC}"
        echo -e "    OpenAI:    ${CYAN}https://platform.openai.com/api-keys${NC}"
        echo -e "    GitHub:    ${CYAN}https://github.com/settings/tokens${NC}"
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 询问是否现在创建 .env
        read -r -p "  是否现在创建 .env 文件? (y/n): " CREATE_ENV 2>/dev/null || CREATE_ENV="n"
        if [ "${CREATE_ENV}" = "y" ] || [ "${CREATE_ENV}" = "Y" ]; then
            cp "${ENV_EXAMPLE}" "${ENV_FILE}"
            ok ".env 已从模板创建: ${ENV_FILE}"
            warn "请记得编辑 ${ENV_FILE} 填入真实 key!"
        else
            info "跳过, 请稍后手动配置 API key"
        fi
    fi
}

# ---- 8. 环境变量加载 (从 .env 文件) ----
load_env_vars() {
    step "8/10" "加载环境变量"

    if [ -f "${ENV_FILE}" ]; then
        info "从 ${ENV_FILE} 加载配置..."
        set -a
        source "${ENV_FILE}"
        set +a
        refresh_github_proxy_url
        ok "环境变量已加载"

        # 验证关键变量
        if [ -n "${ANTHROPIC_AUTH_TOKEN}" ] && [ "${ANTHROPIC_AUTH_TOKEN}" != "your-deepseek-api-key-here" ]; then
            ok "Claude Code (DeepSeek) 已配置"
        else
            warn "ANTHROPIC_AUTH_TOKEN 未设置或仍是占位符"
        fi

        # Gemini CLI
        if [ "${GEMINI_AUTH_METHOD}" = "login" ]; then
            ok "Gemini CLI 使用浏览器 OAuth 登录"
        elif [ -n "${GEMINI_API_KEY}" ] && [ "${GEMINI_API_KEY}" != "your-gemini-api-key-here" ]; then
            ok "Gemini CLI 已配置 (API Key)"
        else
            warn "GEMINI_API_KEY 未设置或仍是占位符"
        fi

        # Codex CLI
        if [ "${CODEX_AUTH_METHOD}" = "login" ]; then
            ok "Codex CLI 使用浏览器 OAuth 登录"
        elif [ -n "${OPENAI_API_KEY}" ] && [ "${OPENAI_API_KEY}" != "your-openai-api-key-here" ]; then
            ok "Codex CLI 已配置 (API Key)"
        else
            warn "OPENAI_API_KEY 未设置或仍是占位符"
        fi

        # GitHub Token
        if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "your-github-token-here" ]; then
            ok "GitHub Token 已配置"
            export GH_TOKEN="${GITHUB_TOKEN}"
        else
            warn "GITHUB_TOKEN 未设置或仍是占位符 (插件安装不受影响, 但 git push 需要)"
        fi

        if [ -n "${GITHUB_PROXY_URL:-}" ]; then
            ok "GitHub 下载代理已配置: ${GITHUB_PROXY_URL}"
        fi
    else
        warn ".env 文件不存在, 跳过环境变量加载"
        info "稍后请执行: source .env"
    fi
}

# ---- 9. Claude Code 配置恢复 ----
restore_config() {
    step "9/10" "Claude Code 配置恢复"

    # 创建目录
    if [ ! -d "${CLAUDE_DIR}" ]; then
        info "创建 ~/.claude 目录..."
        mkdir -p "${CLAUDE_DIR}"
    fi
    ok "~/.claude 目录就绪"

    # 恢复 settings.json
    if [ -f "${SCRIPT_DIR}/config/settings.json" ]; then
        cp -v "${SCRIPT_DIR}/config/settings.json" "${CLAUDE_DIR}/" 2>&1
        ok "settings.json 已恢复"
    fi

    # 恢复 keybindings.json
    if [ -f "${SCRIPT_DIR}/config/keybindings.json" ]; then
        cp -v "${SCRIPT_DIR}/config/keybindings.json" "${CLAUDE_DIR}/" 2>&1
        ok "keybindings.json 已恢复"
    fi
}

# ---- 10. Claude Code 插件自动安装 ----
install_plugins() {
    step "10/10" "Claude Code 插件自动安装"

    CLAUDE_BIN="${NODE_INSTALL_PREFIX}/bin/claude"
    if [ ! -x "${CLAUDE_BIN}" ]; then
        warn "venv claude 命令未找到, 跳过插件安装"
        return
    fi

    info "添加 marketplaces ..."
    if [ -n "${GITHUB_PROXY_URL:-}" ]; then
        info "Claude marketplace GitHub 克隆使用代理: ${GITHUB_PROXY_URL}"
    fi

    # 添加 marketplaces (幂等操作, 已存在则跳过)
    if run_with_github_proxy "${CLAUDE_BIN}" plugin marketplace add https://github.com/anthropics/claude-plugins-official 2>&1; then
        ok "marketplace claude-plugins-official 已就绪"
    else
        warn "marketplace claude-plugins-official 添加失败"
    fi

    if run_with_github_proxy "${CLAUDE_BIN}" plugin marketplace add https://github.com/tanweai/pua 2>&1; then
        ok "marketplace pua-skills 已就绪"
    else
        warn "marketplace pua-skills 添加失败"
    fi

    if run_with_github_proxy "${CLAUDE_BIN}" plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode.git 2>&1; then
        ok "marketplace omc 已就绪"
    else
        warn "marketplace omc 添加失败"
    fi

    if run_with_github_proxy "${CLAUDE_BIN}" plugin marketplace add https://github.com/jarrodwatts/claude-hud 2>&1; then
        ok "marketplace claude-hud 已就绪"
    else
        warn "marketplace claude-hud 添加失败"
    fi

    ok "marketplaces 配置完成"

    info "安装插件 (可能需要几分钟)..."

    PLUGINS=(
        "superpowers@claude-plugins-official"
        "code-review@claude-plugins-official"
        "github@claude-plugins-official"
        "skill-creator@claude-plugins-official"
        "pua@pua-skills"
        "oh-my-claudecode@omc"
        "claude-hud@claude-hud"
    )

    for plugin in "${PLUGINS[@]}"; do
        info "安装 ${plugin} ..."
        if "${CLAUDE_BIN}" plugin install "${plugin}" 2>&1; then
            ok "${plugin} 安装成功"
        else
            warn "${plugin} 安装失败 (可稍后手动: claude plugin install ${plugin})"
        fi
    done

    ok "插件安装流程完成"
}

# ---- 完成提示 ----
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}   ✓ 部署完成! (uv 版)                ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  ${CYAN}环境概览:${NC}"
    echo -e "    uv 版本:      $(uv --version 2>/dev/null || echo 'unknown')"
    echo -e "    venv 目录:    ${VENV_DIR}"
    echo -e "    CLI 目录:     ${NODE_INSTALL_PREFIX}/bin"
    echo -e "    激活命令:      ${GREEN}source ${VENV_DIR}/bin/activate${NC}"
    echo -e "    Node.js:      $("${NODE_INSTALL_PREFIX}/bin/node" --version 2>/dev/null || echo 'unknown')"
    echo -e "    npm:          $("${NODE_INSTALL_PREFIX}/bin/npm" --version 2>/dev/null || echo 'unknown')"
    echo -e "    Claude Code:   ${GREEN}claude${NC}"
    echo -e "    Gemini CLI:    ${GREEN}gemini${NC}"
    echo -e "    Codex CLI:     ${GREEN}codex${NC}"
    echo -e "    配置目录:      ${CLAUDE_DIR}"
    echo ""

    if [ -d "${VENV_DIR}" ]; then
        echo -e "  ${CYAN}提示:${NC} CLI 工具已安装到 venv 内, 激活后使用:"
        echo -e "    ${GREEN}source ${VENV_DIR}/bin/activate${NC}"
        echo ""
    fi

    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "  ${YELLOW}⚠  别忘了配置 API key:${NC}"
        echo -e "    cp ${ENV_EXAMPLE} ${ENV_FILE}"
        echo -e "    vim ${ENV_FILE}"
        echo ""
    fi

    echo -e "  ${CYAN}启动方式:${NC}"
    echo -e "    ${GREEN}source ${VENV_DIR}/bin/activate${NC}"
    echo -e "    claude"
    echo -e "    gemini"
    echo -e "    codex"
    echo ""

    echo -e "  ${CYAN}各 CLI 扩展/插件安装状态:${NC}"
    echo ""
    echo -e "    ${GREEN}Claude Code (7 插件):${NC} superpowers, code-review, github, skill-creator, pua, oh-my-claudecode, claude-hud"
    echo -e "    ${GREEN}Gemini CLI (1 扩展):${NC} superpowers"
    echo -e "    ${YELLOW}Codex CLI (1 插件):${NC} superpowers — ⚠️ 需手动: codex → /plugins → 搜索安装"
    echo ""

    echo -e "  ${CYAN}重新加载 Claude Code 插件 (如需要):${NC}"
    echo -e "    进入 Claude Code 后执行 /plugin reload"
    echo ""

    echo -e "  ${CYAN}▸ 环境变量已配置:${NC}"
    echo -e "    ANTHROPIC_BASE_URL       = ${ANTHROPIC_BASE_URL}"
    echo -e "    ANTHROPIC_MODEL          = ${ANTHROPIC_MODEL}"
    echo -e "    ANTHROPIC_DEFAULT_HAIKU  = ${ANTHROPIC_DEFAULT_HAIKU_MODEL}"
    echo -e "    CLAUDE_CODE_SUBAGENT     = ${CLAUDE_CODE_SUBAGENT_MODEL}"
    if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "your-github-token-here" ]; then
        echo -e "    GITHUB_TOKEN             = ***已设置*** (GitHub 认证就绪)"
    else
        echo -e "    GITHUB_TOKEN             = (未设置, git push 需要手动认证)"
    fi
    if [ -n "${GITHUB_PROXY_URL:-}" ]; then
        echo -e "    GITHUB_PROXY_URL         = ${GITHUB_PROXY_URL}"
    fi
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    banner
    preload_env_vars

    check_system
    install_uv
    setup_venv
    install_nodejs
    install_claude_code
    install_gemini_cli
    install_codex_cli
    setup_github_auth
    setup_api_key
    load_env_vars
    restore_config
    install_plugins
    print_summary
}

main "$@"
