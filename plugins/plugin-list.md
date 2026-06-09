# 各 CLI 安装内容详表

> 三个 CLI 各自安装的扩展/插件独立管理，互不通用。

---

## 🤖 Claude Code — 7 插件 + 4 市场

脚本自动执行 `claude plugin install`，安装到 `~/.claude/plugins/`。

### 1. superpowers@claude-plugins-official (v5.1.0)

系统化软件开发方法论，14 个技能覆盖完整开发周期。

**核心技能**: brainstorming → writing-plans → executing-plans → subagent-driven-development → test-driven-development → requesting-code-review → receiving-code-review → verification-before-completion → finishing-a-development-branch

**辅助技能**: using-superpowers, using-git-worktrees, dispatching-parallel-agents, writing-skills, systematic-debugging

### 2. code-review@claude-plugins-official

`/code-review` 命令对当前 diff 做 correctness 检查 + 简化/效率优化。

### 3. github@claude-plugins-official

GitHub 集成。PR 操作、issue 管理、代码搜索等。

### 4. skill-creator@claude-plugins-official

创建和管理自定义技能的框架。`/skill-creator` 引导式创建新技能。

### 5. pua@pua-skills (v3.4.6)

PUA 高效工作流。13 种企业文化风格 (阿里/字节/华为/腾讯/Netflix 等)，覆盖需求分析、架构设计、MVP 交付、KPI 报告。

### 6. oh-my-claudecode@omc (v4.14.4)

增强型工作流和工具集:
- **MCP 工具 (30+)**: ast_grep, lsp_* (11 个 LSP 工具), notepad, project_memory, shared_memory, wiki, state, python_repl
- **Agent 类型 (32+)**: general-purpose, Explore, Plan, debugger, code-reviewer, security-reviewer, test-engineer 等
- **Hook (36 个)**: PreToolUse, PostToolUse, PreCompact 等自动化钩子
- **模式**: autopilot, ralph, ultrawork, ultraqa, team, deep-interview 等

### 7. claude-hud@claude-hud (v0.1.0)

终端状态栏。显示模型、token 使用、session 时间。启用: `/hud setup`

### Marketplace 源

| 市场 | 来源 | 类型 |
|------|------|------|
| claude-plugins-official | `anthropics/claude-plugins-official` | github |
| pua-skills | `tanweai/pua` | github |
| omc | `Yeachan-Heo/oh-my-claudecode` | git |
| claude-hud | `jarrodwatts/claude-hud` | github |

---

## 🔮 Gemini CLI — 1 扩展

脚本自动执行 `gemini extensions install`，安装到 `~/.gemini/extensions/`。

### superpowers (v5.1.0, 来源: `obra/superpowers`)

与 Claude Code 版功能相同，14 个开发工作流技能: brainstorming, writing-plans, executing-plans, test-driven-development, systematic-debugging, subagent-driven-development, requesting-code-review, receiving-code-review, verification-before-completion, finishing-a-development-branch, using-superpowers, using-git-worktrees, dispatching-parallel-agents, writing-skills

```bash
# 手动安装命令 (脚本已自动执行)
gemini extensions install https://github.com/obra/superpowers

# 查看已安装
gemini extensions list

# 更新
gemini extensions update superpowers
```

---

## ⚡ Codex CLI — 1 插件

需要手动在 Codex 交互界面内安装，无法命令行自动化。

### superpowers (来源: OpenAI 官方插件市场)

与 Claude Code / Gemini 版功能相同，14 个开发工作流技能。

```bash
# 手动安装步骤
codex                 # 进入交互界面
/plugins              # 打开插件搜索
# → 搜索 "superpowers"
# → 点击 Install Plugin
```

> 来源: [github.com/obra/superpowers](https://github.com/obra/superpowers)
