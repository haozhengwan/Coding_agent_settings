#!/bin/bash
# Shared download helpers. Source after loading .env; settings are read at call time.
download_file() {
    local url="$1" output="$2" attempt status=1 partial
    local attempts="${DOWNLOAD_ATTEMPTS:-3}"
    local -a address_options=()
    if ! [[ "$attempts" =~ ^[1-9][0-9]*$ ]]; then
        echo 'DOWNLOAD_ATTEMPTS must be a positive integer' >&2
        return 2
    fi
    [ "${DOWNLOAD_IPV4:-0}" != 1 ] || address_options=(--ipv4)
    partial="$(mktemp "${output}.part.XXXXXX")" || return 1
    for ((attempt=1; attempt<=attempts; attempt++)); do
        if curl -fLsS "${address_options[@]}" \
            --connect-timeout "${DOWNLOAD_CONNECT_TIMEOUT:-15}" \
            --max-time "${DOWNLOAD_MAX_TIME:-600}" \
            --speed-limit 1024 --speed-time 60 \
            --output "$partial" "$url"; then
            if [ -s "$partial" ]; then
                if mv -f "$partial" "$output"; then return 0; fi
                status=1
                break
            fi
            status=1
        else
            status=$?
        fi
        echo "Download attempt ${attempt}/${attempts} failed (curl status ${status})." >&2
        if [ "$attempt" -lt "$attempts" ]; then sleep "${DOWNLOAD_RETRY_DELAY:-2}"; fi
    done
    rm -f "$partial"
    echo 'Download failed. Check the proxy, DNS, or configured download source.' >&2
    return "$status"
}

# The optional prefix is only applied to public GitHub release downloads.
download_github_file() {
    local url="$1" output="$2" prefix="${GITHUB_PROXY_URL:-${GH_PROXY_URL:-}}"
    if [ -n "$prefix" ]; then
        if download_file "${prefix%/}/${url}" "$output"; then return 0; fi
        echo 'GitHub proxy failed; trying the official source.' >&2
    fi
    download_file "$url" "$output"
}

# Pass the npm executable, optionally preceded by a runner such as conda run.
npm_install_with_retry() {
    local package="$1"
    shift
    local -a registry_options=()
    if [ -n "${NPM_REGISTRY:-}" ]; then registry_options=(--registry "$NPM_REGISTRY"); fi
    "$@" install -g "$package" "${registry_options[@]}" \
        --fetch-retries=3 --fetch-retry-mintimeout=2000 \
        --fetch-retry-maxtimeout=10000 --fetch-timeout=120000
}
