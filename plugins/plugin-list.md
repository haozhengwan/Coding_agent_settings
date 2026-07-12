# 各 CLI 安装内容详表

> 三个 CLI 各自安装的扩展/插件独立管理，互不通用。

---

## 🤖 Claude Code — 6 插件 + 4 市场

脚本自动执行 `claude plugin install`，安装到 `~/.claude/plugins/`。

### 1. code-review@claude-plugins-official

`/code-review` 命令对当前 diff 做 correctness 检查 + 简化/效率优化。

### 2. github@claude-plugins-official

GitHub 集成。PR 操作、issue 管理、代码搜索等。

### 3. skill-creator@claude-plugins-official

创建和管理自定义技能的框架。`/skill-creator` 引导式创建新技能。

### 4. pua@pua-skills (v3.4.6)

PUA 高效工作流。13 种企业文化风格 (阿里/字节/华为/腾讯/Netflix 等)，覆盖需求分析、架构设计、MVP 交付、KPI 报告。

### 5. oh-my-claudecode@omc (v4.14.4)

增强型工作流和工具集:
- **MCP 工具 (30+)**: ast_grep, lsp_* (11 个 LSP 工具), notepad, project_memory, shared_memory, wiki, state, python_repl
- **Agent 类型 (32+)**: general-purpose, Explore, Plan, debugger, code-reviewer, security-reviewer, test-engineer 等
- **Hook (36 个)**: PreToolUse, PostToolUse, PreCompact 等自动化钩子
- **模式**: autopilot, ralph, ultrawork, ultraqa, team, deep-interview 等

### 6. claude-hud@claude-hud (v0.1.0)

终端状态栏。显示模型、token 使用、session 时间。启用: `/hud setup`

### Marketplace 源

| 市场 | 来源 | 类型 |
|------|------|------|
| claude-plugins-official | `anthropics/claude-plugins-official` | github |
| pua-skills | `tanweai/pua` | github |
| omc | `Yeachan-Heo/oh-my-claudecode` | git |
| claude-hud | `jarrodwatts/claude-hud` | github |

---

## 🔮 Gemini CLI

脚本不自动安装 Gemini 扩展。

---

## ⚡ Codex CLI

脚本不自动安装 Codex 插件。
