#!/bin/bash
# Claude Code 配置一键恢复脚本
set -e

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Claude Code 配置恢复 ==="
echo ""
echo "源目录: ${SCRIPT_DIR}"
echo "目标目录: ${CLAUDE_DIR}"
echo ""

# 检查并创建 Claude 目录
if [ ! -d "${CLAUDE_DIR}" ]; then
    echo "[1/3] 创建 ~/.claude 目录..."
    mkdir -p "${CLAUDE_DIR}"
else
    echo "[1/3] ~/.claude 目录已存在"
fi

# 恢复配置
echo "[2/3] 恢复配置文件..."
cp -v "${SCRIPT_DIR}/config/settings.json" "${CLAUDE_DIR}/"

if [ -f "${SCRIPT_DIR}/config/keybindings.json" ]; then
    cp -v "${SCRIPT_DIR}/config/keybindings.json" "${CLAUDE_DIR}/"
fi

# 恢复 plugin known_marketplaces (确保插件源在 setting 之前已配置)
echo "[3/3] 恢复插件信息..."
mkdir -p "${CLAUDE_DIR}/plugins"
cp -v "${SCRIPT_DIR}/plugins/known_marketplaces.json" "${CLAUDE_DIR}/plugins/"
cp -v "${SCRIPT_DIR}/plugins/installed_plugins.json" "${CLAUDE_DIR}/plugins/"

echo ""
echo "✓ 配置恢复完成！"
echo ""
echo "启动 Claude Code 后，插件会自动从配置的 marketplaces 拉取。"
echo "如需手动安装插件："
echo ""
echo "  /plugin install superpowers@claude-plugins-official"
echo "  /plugin install code-review@claude-plugins-official"
echo "  /plugin install github@claude-plugins-official"
echo "  /plugin install skill-creator@claude-plugins-official"
echo "  /plugin install pua@pua-skills"
echo "  /plugin install oh-my-claudecode@omc"
echo "  /plugin install claude-hud@claude-hud"
echo ""
echo "  # 配置 HUD"
echo "  /hud setup"
