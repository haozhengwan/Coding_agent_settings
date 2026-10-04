# AI 编程工具配置清单

部署 Claude Code、Codex CLI 和 Antigravity CLI（`agy`）。默认使用 curl 下载官方原生安装器，conda / uv 为可选方案。不安装插件、扩展、marketplace 或 Gemini CLI，不创建或恢复 `CLAUDE.md` / `GEMINI.md`。

| 文件 | 说明 |
|------|------|
| README.md | 安装、配置及启动指南 |
| restore.sh | 默认原生安装；可选 --conda / --uv |
| restore_conda.sh | 可选 conda 版部署脚本 |
| restore_uv.sh | 可选 uv + venv 版部署脚本 |
| lib/network.sh | 下载、超时、代理及 npm 重试函数 |
| lib/installers.sh | 完整下载后执行官方安装器、检查 CLI 及安装 Antigravity |
| tests/test_network.py | 离线网络故障回归检查 |
| tests/test_installers.py | 原生安装与入口离线回归检查 |
| .env.example | API Key 及网络环境变量模板 |
| .gitignore | 排除密钥、备份、临时文件及 .omc 会话缓存 |
| config/settings.json | Claude Code 深色主题，关闭官方插件市场自动注册 |
| config/keybindings.json | Claude Code 默认快捷键 |
| MANIFEST.md | 本文件 |

原生模式依次检查系统、安装三个 CLI、备份并恢复 Claude Code 配置。conda / uv 模式另保留环境创建、GitHub 认证和 API Key 交互设置；Antigravity 在所有模式中均通过官方原生安装器安装到 `~/.local/bin/agy`。

使用方法见 [README.md](README.md)。
