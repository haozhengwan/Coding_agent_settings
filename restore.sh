#!/bin/bash
# Claude Code + Codex CLI + Antigravity CLI; native installers by default.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/network.sh"
source "${SCRIPT_DIR}/lib/installers.sh"

usage() {
    cat <<'EOF'
用法: bash restore.sh [--native|--conda|--uv]

  --native  默认：通过 curl 下载官方安装器，无需 conda、uv 或 Node.js
  --conda   可选：通过 conda 环境安装 Claude Code / Codex
  --uv      可选：通过 uv + venv + Node.js 安装 Claude Code / Codex
  --help    显示帮助

三种方式均安装 Antigravity CLI (agy)，不安装插件或编辑器扩展。
EOF
}

main() {
    if [ "$#" -gt 1 ]; then
        usage >&2
        return 2
    fi
    case "${1:---native}" in
        --help|-h) usage; return 0 ;;
        --conda) exec bash "${SCRIPT_DIR}/restore_conda.sh" ;;
        --uv) exec bash "${SCRIPT_DIR}/restore_uv.sh" ;;
        --native) ;;
        *) usage >&2; return 2 ;;
    esac

    if [ -f "${SCRIPT_DIR}/.env" ]; then
        set -a
        source "${SCRIPT_DIR}/.env"
        set +a
    fi
    export PATH="${HOME}/.local/bin:${PATH}"
    export CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1

    printf '\n[1/5] 系统检查（原生安装）\n'
    case "$(uname -s):$(uname -m)" in
        Linux:x86_64|Linux:aarch64|Linux:arm64|Darwin:x86_64|Darwin:arm64) ;;
        *) printf '原生安装支持 Linux/macOS 的 x64 和 ARM64。\n' >&2; return 1 ;;
    esac
    local tool
    for tool in curl tar; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf '缺少 %s，请通过系统包管理器安装后重试。\n' "$tool" >&2
            return 1
        fi
    done

    printf '\n[2/5] Claude Code\n'
    install_native_cli claude "${CLAUDE_INSTALLER_URL:-https://claude.ai/install.sh}" bash

    printf '\n[3/5] Codex CLI\n'
    install_native_cli codex "${CODEX_INSTALLER_URL:-https://chatgpt.com/codex/install.sh}" sh

    printf '\n[4/5] Antigravity CLI\n'
    install_antigravity

    printf '\n[5/5] 恢复 Claude Code 配置\n'
    local config_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}" name backup_dir=""
    mkdir -p "$config_dir"
    for name in settings.json keybindings.json; do
        if [ -e "${config_dir}/${name}" ]; then
            if [ -z "$backup_dir" ]; then
                backup_dir="$(mktemp -d "${config_dir}/restore-backup.XXXXXX")"
                printf '原配置备份：%s\n' "$backup_dir"
            fi
            cp -p "${config_dir}/${name}" "${backup_dir}/${name}"
        fi
        cp "${SCRIPT_DIR}/config/${name}" "${config_dir}/${name}"
    done

    cat <<'EOF'

部署完成。新终端若找不到命令，请将以下内容加入 ~/.bashrc 或 ~/.zshrc：
  export PATH="$HOME/.local/bin:$PATH"

启动：
  claude    # Claude Code
  codex     # Codex CLI
  agy       # Antigravity CLI

首次启动按各工具提示登录。需要 API Key 时，编辑本仓库的 .env 后运行：
  set -a; source .env; set +a

GitHub 认证按需执行 gh auth login（需要自行安装 gh）。
EOF
    if [ ! -f "${SCRIPT_DIR}/.env" ]; then
        printf '\nAPI Key 模板：%s/.env.example（按需复制为 .env）。\n' "$SCRIPT_DIR"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
