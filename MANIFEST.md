# AI CLI 工具配置清单

仅部署 Claude Code 和 Codex CLI，不包含插件、扩展或 marketplace。

| 文件 | 说明 |
|------|------|
| README.md | 部署、配置及启动指南 |
| restore.sh | conda 版部署脚本 |
| restore_uv.sh | uv + venv 版部署脚本 |
| lib/network.sh | 共享下载、超时和 npm 重试函数 |
| tests/test_network.py | 离线网络故障回归检查 |
| .env.example | Claude Code、Codex 和 GitHub 环境变量模板 |
| .gitignore | 排除密钥、备份及临时文件 |
| config/settings.json | Claude Code 深色主题设置 |
| config/keybindings.json | Claude Code 默认快捷键 |
| MANIFEST.md | 本文件 |

两个脚本的部署流程：

1. 系统环境检查。
2. 创建运行环境：conda 或 uv + venv + Node.js。
3. 安装 Claude Code。
4. 安装 Codex CLI。
5. 配置 GitHub 认证。
6. 配置 API Key 模板及 .env。
7. 加载环境变量。
8. 恢复 Claude Code 配置。

环境变量和使用方法见 [README.md](README.md)。
