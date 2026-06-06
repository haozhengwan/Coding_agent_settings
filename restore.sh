#!/bin/bash
# ============================================================
#  AI CLI 工具一键部署脚本
#  涵盖: Anaconda → Node.js → Claude Code / Gemini CLI / Codex CLI → API Key → 配置恢复
# ============================================================
set -e

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

banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   AI CLI 工具一键部署                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Claude Code + Gemini CLI + Codex CLI  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

# ---- 1. 系统环境检查 ----
check_system() {
    step "1/9" "系统环境检查"

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

    # 检查 git
    if ! command -v git &>/dev/null; then
        warn "git 未安装, 尝试安装..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq git
        elif command -v yum &>/dev/null; then
            yum install -y -q git
        elif command -v dnf &>/dev/null; then
            dnf install -y -q git
        fi
    fi
    ok "git $(git --version 2>/dev/null | awk '{print $NF}')"
}

# ---- 2. Anaconda/Miniconda 安装 ----
install_conda() {
    step "2/9" "Anaconda/Miniconda 环境"

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
                CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${ARCH}"
                ;;
            Darwin)
                CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-${ARCH}"
                ;;
            *)
                fail "不支持的操作系统: ${OS}"
                exit 1
                ;;
        esac

        CONDA_INSTALLER="/tmp/miniconda_installer.sh"
        info "下载 ${CONDA_URL}"
        curl -fsSL "${CONDA_URL}" -o "${CONDA_INSTALLER}" || {
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
        conda create -n "${CONDA_ENV_NAME}" python="${PYTHON_VERSION}" -y > /dev/null 2>&1
        ok "conda 环境 '${CONDA_ENV_NAME}' 创建完成"
    fi

    # 安装 Node.js
    info "在 '${CONDA_ENV_NAME}' 环境中安装 Node.js ${NODE_VERSION}..."
    conda install -n "${CONDA_ENV_NAME}" "nodejs=${NODE_VERSION}" -c conda-forge -y > /dev/null 2>&1
    ok "Node.js $($(conda run -n "${CONDA_ENV_NAME}" which node) --version 2>/dev/null)"
    ok "npm $($(conda run -n "${CONDA_ENV_NAME}" which npm) --version 2>/dev/null)"

    # 导出 NODE_PATH 供后续步骤使用
    NODE_BIN="$(conda run -n "${CONDA_ENV_NAME}" which node)"
    NPM_BIN="$(conda run -n "${CONDA_ENV_NAME}" which npm)"
}

# ---- 3. Claude Code CLI 安装 ----
install_claude_code() {
    step "3/9" "Claude Code CLI 安装"

    if command -v claude &>/dev/null; then
        ok "claude 已安装: $(claude --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 npm 安装 @anthropic-ai/claude-code ..."
        conda run -n "${CONDA_ENV_NAME}" npm install -g @anthropic-ai/claude-code > /dev/null 2>&1
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

# ---- 4. Gemini CLI 安装 ----
install_gemini_cli() {
    step "4/9""Gemini CLI 安装"

    if conda run -n "${CONDA_ENV_NAME}" which gemini &>/dev/null; then
        ok "gemini 已安装: $(conda run -n "${CONDA_ENV_NAME}" gemini --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 npm 安装 @google/gemini-cli ..."
        conda run -n "${CONDA_ENV_NAME}" npm install -g @google/gemini-cli > /dev/null 2>&1
        ok "Gemini CLI 安装完成"
    fi

    GEMINI_PATH="$(conda run -n "${CONDA_ENV_NAME}" which gemini 2>/dev/null || echo '')"
    if [ -n "${GEMINI_PATH}" ]; then
        ok "gemini 路径: ${GEMINI_PATH}"
    else
        warn "未能检测到 gemini 命令, 可能需要重启终端或手动加入 PATH"
    fi
}

# ---- 5. Codex CLI 安装 ----
install_codex_cli() {
    step "5/9""Codex CLI 安装"

    if conda run -n "${CONDA_ENV_NAME}" which codex &>/dev/null; then
        ok "codex 已安装: $(conda run -n "${CONDA_ENV_NAME}" codex --version 2>/dev/null || echo 'version check skipped')"
    else
        info "通过 npm 安装 @openai/codex ..."
        conda run -n "${CONDA_ENV_NAME}" npm install -g @openai/codex > /dev/null 2>&1
        ok "Codex CLI 安装完成"
    fi

    CODEX_PATH="$(conda run -n "${CONDA_ENV_NAME}" which codex 2>/dev/null || echo '')"
    if [ -n "${CODEX_PATH}" ]; then
        ok "codex 路径: ${CODEX_PATH}"
    else
        warn "未能检测到 codex 命令, 可能需要重启终端或手动加入 PATH"
    fi
}
# ---- 6. API Key 配置 ----
setup_api_key() {
    step "6/9""API Key 配置 (Claude + Gemini + Codex)"

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
        echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 询问是否现在创建 .env
        read -r -p "  是否现在创建 .env 文件? (y/n): " CREATE_ENV
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
    step "7/9""加载环境变量"

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
    else
        warn ".env 文件不存在, 跳过环境变量加载"
        info "稍后请执行: source .env"
    fi
}

# ---- 8. Claude Code 插件自动安装 ----
install_plugins() {
    step "8/9" "Claude Code 插件自动安装"

    CLAUDE_BIN="$(conda run -n "${CONDA_ENV_NAME}" which claude 2>/dev/null || echo '')"
    if [ -z "${CLAUDE_BIN}" ]; then
        warn "claude 命令未找到, 跳过插件安装"
        return
    fi

    info "添加 marketplaces ..."

    # 添加 marketplaces (幂等操作, 已存在则跳过)
    conda run -n "${CONDA_ENV_NAME}" claude plugin marketplace add github:anthropics/claude-plugins-official 2>&1 | while read line; do info "$line"; done || true
    conda run -n "${CONDA_ENV_NAME}" claude plugin marketplace add github:tanweai/pua 2>&1 | while read line; do info "$line"; done || true
    conda run -n "${CONDA_ENV_NAME}" claude plugin marketplace add git:https://github.com/Yeachan-Heo/oh-my-claudecode.git 2>&1 | while read line; do info "$line"; done || true
    conda run -n "${CONDA_ENV_NAME}" claude plugin marketplace add github:jarrodwatts/claude-hud 2>&1 | while read line; do info "$line"; done || true
    ok "marketplaces 已配置"

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
        if conda run -n "${CONDA_ENV_NAME}" claude plugin install "${plugin}" 2>&1 | while read line; do info "$line"; done; then
            ok "${plugin} 安装成功"
        else
            warn "${plugin} 安装失败 (可稍后手动: claude plugin install ${plugin})"
        fi
    done

    ok "插件安装流程完成"
}

# ---- 9. Claude Code 配置恢复 ----
restore_config() {
    step "9/9" "Claude Code 配置恢复"

    # 创建目录
    if [ ! -d "${CLAUDE_DIR}" ]; then
        info "创建 ~/.claude 目录..."
        mkdir -p "${CLAUDE_DIR}"
    fi
    ok "~/.claude 目录就绪"

    # 恢复 settings.json
    if [ -f "${SCRIPT_DIR}/config/settings.json" ]; then
        cp -v "${SCRIPT_DIR}/config/settings.json" "${CLAUDE_DIR}/" 2>&1 | while read line; do info "$line"; done
        ok "settings.json 已恢复"
    fi

    # 恢复 keybindings.json
    if [ -f "${SCRIPT_DIR}/config/keybindings.json" ]; then
        cp -v "${SCRIPT_DIR}/config/keybindings.json" "${CLAUDE_DIR}/" 2>&1 | while read line; do info "$line"; done
        ok "keybindings.json 已恢复"
    fi

    # 恢复插件 marketplaces
    if [ -f "${SCRIPT_DIR}/plugins/known_marketplaces.json" ]; then
        mkdir -p "${CLAUDE_DIR}/plugins"
        cp -v "${SCRIPT_DIR}/plugins/known_marketplaces.json" "${CLAUDE_DIR}/plugins/" 2>&1 | while read line; do info "$line"; done
        ok "known_marketplaces.json 已恢复"
    fi

    if [ -f "${SCRIPT_DIR}/plugins/installed_plugins.json" ]; then
        cp -v "${SCRIPT_DIR}/plugins/installed_plugins.json" "${CLAUDE_DIR}/plugins/" 2>&1 | while read line; do info "$line"; done
        ok "installed_plugins.json 已恢复"
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
    echo -e "    Gemini CLI:    ${GREEN}gemini${NC}"
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
    echo -e "    ${GREEN}# Gemini CLI${NC}"
    echo -e "    gemini"
    echo ""
    echo -e "    ${GREEN}# Codex CLI${NC}"
    echo -e "    codex"
    echo ""

    echo -e "  ${CYAN}插件已自动安装:${NC}"
    echo -e "    superpowers, code-review, github, skill-creator,"
    echo -e "    pua, oh-my-claudecode, claude-hud"
    echo ""

    echo -e "  ${CYAN}重新加载插件 (如需要):${NC}"
    echo -e "    进入 Claude Code 后执行 /plugin reload"
    echo ""

    echo -e "  ${CYAN}▸ 环境变量已配置:${NC}"
    echo -e "    ANTHROPIC_BASE_URL       = ${ANTHROPIC_BASE_URL}"
    echo -e "    ANTHROPIC_MODEL          = ${ANTHROPIC_MODEL}"
    echo -e "    ANTHROPIC_DEFAULT_HAIKU  = ${ANTHROPIC_DEFAULT_HAIKU_MODEL}"
    echo -e "    CLAUDE_CODE_SUBAGENT     = ${CLAUDE_CODE_SUBAGENT_MODEL}"
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    banner

    check_system
    install_conda
    install_claude_code
    install_gemini_cli
    install_codex_cli
    setup_api_key
    load_env_vars
    install_plugins
    restore_config
    print_summary
}

main "$@"
