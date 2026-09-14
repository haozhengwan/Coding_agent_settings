#!/bin/bash
# ============================================================
#  AI CLI 工具一键部署脚本 (8 步)
#  涵盖: Anaconda → Node.js → Claude Code / Codex CLI → GitHub 认证 → API Key → 配置恢复
# ============================================================
set -eo pipefail

# ---- 可配置变量 ----
CONDA_INSTALL_DIR="${CONDA_INSTALL_DIR:-${HOME}/anaconda3}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-claude}"
NODE_VERSION="${NODE_VERSION:-20}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

# ---- Claude Code 配置 (可修改) ----
ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.deepseek.com/anthropic}"
ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-deepseek-v4-pro[1m]}"
ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-v4-flash}"
CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDE_CODE_SUBAGENT_MODEL:-deepseek-v4-flash}"

# ---- Codex CLI 配置 (可修改) ----
# 认证方式: "login" (浏览器OAuth, 默认) 或 "api_key"
CODEX_AUTH_METHOD="${CODEX_AUTH_METHOD:-login}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"
source "${SCRIPT_DIR}/lib/network.sh"

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

banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   AI CLI 工具一键部署                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Claude Code + Codex CLI               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

# ---- 1. 系统环境检查 ----
check_system() {
    step "1/8" "系统环境检查"

    OS="$(uname -s)"
    ARCH="$(uname -m)"
    info "操作系统: ${OS} (${ARCH})"

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

    # 检查 git (系统级, VS Code 等 IDE 需要)
    # 注意: 即使 conda 环境有 git, 系统级 git 也必须存在供 IDE 使用
    if [ -x "/usr/bin/git" ]; then
        ok "git 系统级: $(/usr/bin/git --version 2>/dev/null | awk '{print $NF}')"
    elif command -v git &>/dev/null; then
        warn "git 仅在 conda 环境可用, 安装系统级 git (VS Code 需要)..."
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
}

# ---- 2. Anaconda/Miniconda 安装 ----
install_conda() {
    step "2/8" "Anaconda/Miniconda 环境"

    # 如果 conda 已存在
    if command -v conda &>/dev/null; then
        ok "conda 已安装: $(conda --version 2>/dev/null)"
        CONDA_EXISTING="yes"
    elif [ -f "${CONDA_INSTALL_DIR}/bin/conda" ]; then
        ok "conda 已存在于 ${CONDA_INSTALL_DIR}"
        CONDA_EXISTING="yes"
        # 初始化 shell
        eval "$(${CONDA_INSTALL_DIR}/bin/conda shell.bash hook)" 2>/dev/null || true
    else
        CONDA_EXISTING="no"
    fi

    if [ "${CONDA_EXISTING}" = "no" ]; then
        warn "conda 未安装, 开始下载 Miniconda..."

        case "${OS}" in
            Linux)
                CONDA_URL="${MINICONDA_BASE_URL:-https://repo.anaconda.com/miniconda}/Miniconda3-latest-Linux-${ARCH}.sh"
                ;;
            Darwin)
                CONDA_URL="${MINICONDA_BASE_URL:-https://repo.anaconda.com/miniconda}/Miniconda3-latest-MacOSX-${ARCH}.sh"
                ;;
            *)
                fail "不支持的操作系统: ${OS}"
                exit 1
                ;;
        esac

        CONDA_INSTALLER="/tmp/miniconda_installer.sh"
        info "下载 ${CONDA_URL}"
        download_file "${CONDA_URL}" "${CONDA_INSTALLER}" || {
            fail "下载失败, 请检查网络或手动安装 Anaconda: https://www.anaconda.com/download"
            exit 1
        }

        info "安装到 ${CONDA_INSTALL_DIR} (静默模式)"
        bash "${CONDA_INSTALLER}" -b -p "${CONDA_INSTALL_DIR}" > /dev/null 2>&1
        rm -f "${CONDA_INSTALLER}"

        # 初始化
        eval "$(${CONDA_INSTALL_DIR}/bin/conda shell.bash hook)" 2>/dev/null || true
        ok "Miniconda 安装完成: $(${CONDA_INSTALL_DIR}/bin/conda --version)"
    fi

    # 配置 conda 基础设置
    info "配置 conda..."
    conda config --set auto_activate_base false 2>/dev/null || true
    conda config --set channel_priority flexible 2>/dev/null || true

    # 创建或检查专用环境
    if conda env list 2>/dev/null | grep -q "^${CONDA_ENV_NAME} "; then
        ok "conda 环境 '${CONDA_ENV_NAME}' 已存在"
    else
        info "创建 conda 环境 '${CONDA_ENV_NAME}' (Python ${PYTHON_VERSION})..."
        conda create -n "${CONDA_ENV_NAME}" python="${PYTHON_VERSION}" -y
        ok "conda 环境 '${CONDA_ENV_NAME}' 创建完成"
    fi

    # 安装 Node.js
    info "在 '${CONDA_ENV_NAME}' 环境中安装 Node.js ${NODE_VERSION}..."
    conda install -n "${CONDA_ENV_NAME}" "nodejs=${NODE_VERSION}" -c conda-forge -y
    ok "Node.js $($(conda run -n "${CONDA_ENV_NAME}" which node) --version 2>/dev/null)"
    ok "npm $($(conda run -n "${CONDA_ENV_NAME}" which npm) --version 2>/dev/null)"

    # 安装 git (版本控制工具)
    info "在 '${CONDA_ENV_NAME}' 环境中安装 git..."
    conda install -n "${CONDA_ENV_NAME}" git -c conda-forge -y
    ok "git $(conda run -n "${CONDA_ENV_NAME}" git --version 2>/dev/null)"

    # 导出 NODE_PATH 供后续步骤使用
    NODE_BIN="$(conda run -n "${CONDA_ENV_NAME}" which node)"
    NPM_BIN="$(conda run -n "${CONDA_ENV_NAME}" which npm)"
}

# ---- 3. Claude Code CLI 安装 ----
install_claude_code() {
    step "3/8" "Claude Code CLI 安装"

    if command -v claude &>/dev/null; then
        ok "claude 已安装: $(claude --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 npm 安装 @anthropic-ai/claude-code ..."
        npm_install_with_retry @anthropic-ai/claude-code conda run -n "${CONDA_ENV_NAME}" npm
        ok "Claude Code CLI 安装完成"
    fi

    # 确认
    CLAUDE_PATH="$(conda run -n "${CONDA_ENV_NAME}" which claude 2>/dev/null || echo '')"
    if [ -n "${CLAUDE_PATH}" ]; then
        ok "claude 路径: ${CLAUDE_PATH}"
    else
        warn "未能检测到 claude 命令, 可能需要重启终端或手动加入 PATH"
    fi
}

# ---- 4. Codex CLI 安装 ----
install_codex_cli() {
    step "4/8" "Codex CLI 安装"

    if conda run -n "${CONDA_ENV_NAME}" which codex &>/dev/null; then
        ok "codex 已安装: $(conda run -n "${CONDA_ENV_NAME}" codex --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 npm 安装 @openai/codex ..."
        npm_install_with_retry @openai/codex conda run -n "${CONDA_ENV_NAME}" npm
        ok "Codex CLI 安装完成"
    fi

    CODEX_PATH="$(conda run -n "${CONDA_ENV_NAME}" which codex 2>/dev/null || echo '')"
    if [ -n "${CODEX_PATH}" ]; then
        ok "codex 路径: ${CODEX_PATH}"
    else
        warn "未能检测到 codex 命令, 可能需要重启终端或手动加入 PATH"
    fi
}
# ---- 5. GitHub 认证配置 ----
setup_github_auth() {
    step "5/8" "GitHub 认证配置 (git + gh CLI + SSH)"

    # 修复 git 安全目录问题 (常见于 root/sudo 场景)
    info "配置 git 安全目录..."
    git config --global --add safe.directory "$(pwd)" 2>/dev/null || true
    git config --global --add safe.directory "${HOME}" 2>/dev/null || true
    ok "git safe.directory 已配置"

    # 安装 GitHub CLI
    if command -v gh &>/dev/null; then
        ok "gh CLI 已安装: $(gh --version 2>/dev/null | head -1)"
    else
        info "在 '${CONDA_ENV_NAME}' 环境中安装 GitHub CLI (gh)..."
        if conda install -n "${CONDA_ENV_NAME}" gh -c conda-forge -y; then
            ok "gh CLI 安装完成: $(conda run -n "${CONDA_ENV_NAME}" gh --version 2>/dev/null | head -1)"
        else
            warn "gh CLI 安装失败, 请手动安装: https://github.com/cli/cli"
        fi
    fi

    # 配置 SSH: 添加 GitHub host key
    info "配置 GitHub SSH host key..."
    mkdir -p "${HOME}/.ssh"
    if ! grep -q "github.com" "${HOME}/.ssh/known_hosts" 2>/dev/null; then
        if ssh-keyscan -T 5 github.com >> "${HOME}/.ssh/known_hosts" 2>/dev/null; then
            ok "GitHub SSH host key 已添加"
        else
            warn "GitHub SSH 不可达, 可使用 HTTPS 认证"
        fi
    else
        ok "GitHub SSH host key 已存在"
    fi

    # 检测认证状态
    local AUTH_OK=false
    local USE_TOKEN=false

    # 方式 1: 环境变量 GITHUB_TOKEN / GH_TOKEN (优先, 无需交互)
    if [ -n "${GITHUB_TOKEN}" ] && [ "${GITHUB_TOKEN}" != "your-github-token-here" ]; then
        info "检测到 GITHUB_TOKEN, 配置 gh CLI..."
        # 设置 GH_TOKEN (gh CLI 也认这个)
        export GH_TOKEN="${GITHUB_TOKEN}"
        # 用 token 登录 gh
        if echo "${GITHUB_TOKEN}" | conda run -n "${CONDA_ENV_NAME}" gh auth login --with-token 2>/dev/null; then
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
        if echo "${GH_TOKEN}" | conda run -n "${CONDA_ENV_NAME}" gh auth login --with-token 2>/dev/null; then
            ok "GitHub 已通过 GH_TOKEN 认证"
            USE_TOKEN=true
            AUTH_OK=true
            git config --global url."https://oauth2:${GH_TOKEN}@github.com/".insteadOf "https://github.com/" 2>/dev/null || true
        fi
    fi

    # 方式 2: gh CLI 已有认证
    if [ "${AUTH_OK}" = false ]; then
        if conda run -n "${CONDA_ENV_NAME}" gh auth status 2>&1 | grep -q "Logged in"; then
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
        echo -e "    conda activate ${CONDA_ENV_NAME}"
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
            conda run -n "${CONDA_ENV_NAME}" gh auth login || {
                warn "gh auth login 失败, 请稍后手动认证"
            }
        else
            info "跳过 GitHub 认证"
        fi
    fi

    ok "GitHub 认证配置完成"
}

# ---- 6. API Key 配置 ----
setup_api_key() {
    step "6/8" "API Key 配置 (Claude + Codex + GitHub)"

    if [ ! -f "${ENV_EXAMPLE}" ]; then
        info "创建 .env.example 模板..."
        cat > "${ENV_EXAMPLE}" << 'EOF'
# ============================================
#  AI CLI 工具 API Key 配置文件
#  复制此文件为 .env 并填入你的真实密钥
#  cp .env.example .env
# ============================================

# ---- 下载网络设置 (可选，两个脚本在下载前加载 .env) ----
# 通用 HTTP 代理，按本机代理端口修改
# HTTPS_PROXY=http://127.0.0.1:7890
# HTTP_PROXY=http://127.0.0.1:7890
# DOWNLOAD_ATTEMPTS=3
# DOWNLOAD_CONNECT_TIMEOUT=15
# DOWNLOAD_MAX_TIME=600
# DOWNLOAD_RETRY_DELAY=2
# DOWNLOAD_IPV4=1
# 自行指定可访问的源；不自动切换到第三方镜像
# NPM_REGISTRY=https://registry.npmjs.org
# NODE_DIST_URL=https://nodejs.org/dist
# MINICONDA_BASE_URL=https://repo.anaconda.com/miniconda
# UV_INSTALLER_URL=https://astral.sh/uv/install.sh

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
        echo -e "  ${CYAN}▸ Codex 默认使用浏览器 OAuth 登录, 无需 API Key${NC}"
        echo -e "  如需 API Key 方式, 在 .env 中设置:"
        echo -e "    CODEX_AUTH_METHOD=api_key"
        echo -e "    OPENAI_API_KEY=your-openai-key"
        echo ""
        echo -e "  获取 API Key:"
        echo -e "    DeepSeek:  ${CYAN}https://platform.deepseek.com/api_keys${NC}"
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

# ---- 7. 环境变量加载 (从 .env 文件) ----
load_env_vars() {
    step "7/8" "加载环境变量"

    if [ -f "${ENV_FILE}" ]; then
        info "从 ${ENV_FILE} 加载配置..."
        set -a
        source "${ENV_FILE}"
        set +a
        ok "环境变量已加载"

        # 验证关键变量
        if [ -n "${ANTHROPIC_AUTH_TOKEN}" ] && [ "${ANTHROPIC_AUTH_TOKEN}" != "your-deepseek-api-key-here" ]; then
            ok "Claude Code (DeepSeek) 已配置"
        else
            warn "ANTHROPIC_AUTH_TOKEN 未设置或仍是占位符"
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
            warn "GITHUB_TOKEN 未设置或仍是占位符 (git push 需要认证)"
        fi
    else
        warn ".env 文件不存在, 跳过环境变量加载"
        info "稍后请执行: source .env"
    fi
}

# ---- 8. Claude Code 配置恢复 ----
restore_config() {
    step "8/8" "Claude Code 配置恢复"

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

# ---- 完成提示 ----
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}   ✓ 部署完成!                         ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  ${CYAN}环境概览:${NC}"
    echo -e "    conda 环境:    ${CONDA_INSTALL_DIR}"
    echo -e "    激活命令:      ${GREEN}conda activate ${CONDA_ENV_NAME}${NC}"
    echo -e "    Claude Code:   ${GREEN}claude${NC}"
    echo -e "    Codex CLI:     ${GREEN}codex${NC}"
    echo -e "    配置目录:      ${CLAUDE_DIR}"
    echo ""

    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "  ${YELLOW}⚠  别忘了配置 API key:${NC}"
        echo -e "    cp ${ENV_EXAMPLE} ${ENV_FILE}"
        echo -e "    vim ${ENV_FILE}"
        echo ""
    fi

    echo -e "  ${CYAN}启动方式:${NC}"
    echo -e "    conda activate ${CONDA_ENV_NAME}"
    echo ""
    echo -e "    ${GREEN}# Claude Code${NC}"
    echo -e "    claude"
    echo ""
    echo -e "    ${GREEN}# Codex CLI${NC}"
    echo -e "    codex"
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
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    banner
    if [ -f "${ENV_FILE}" ]; then
        set -a
        source "${ENV_FILE}"
        set +a
    fi

    check_system
    install_conda
    install_claude_code
    install_codex_cli
    setup_github_auth
    setup_api_key
    load_env_vars
    restore_config
    print_summary
}

main "$@"
