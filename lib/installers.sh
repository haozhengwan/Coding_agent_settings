#!/bin/bash
# Source after lib/network.sh. Download fully before executing an installer.
run_installer() (
    local url="$1" runner="$2" installer
    shift 2
    installer="$(mktemp)" || return 1
    trap 'rm -f "$installer"' EXIT
    download_file "$url" "$installer" || return $?
    "$runner" "$installer" "$@"
)

install_native_cli() {
    local cli="$1" url="$2" runner="$3"
    shift 3
    export PATH="${HOME}/.local/bin:${PATH}"
    if command -v "$cli" >/dev/null 2>&1; then
        printf '%s 已存在，检查版本：\n' "$cli"
    else
        printf '安装 %s：%s\n' "$cli" "$url"
        run_installer "$url" "$runner" "$@" || return $?
        hash -r
    fi
    if ! command -v "$cli" >/dev/null 2>&1; then
        printf '安装后未找到 %s，请检查安装器输出和 PATH。\n' "$cli" >&2
        return 1
    fi
    "$cli" --version
}

install_antigravity() {
    install_native_cli agy \
        "${ANTIGRAVITY_INSTALLER_URL:-https://antigravity.google/cli/install.sh}" \
        bash --skip-aliases --skip-path
}
