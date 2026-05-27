# 已安装插件说明

## 1. superpowers@claude-plugins-official (v5.1.0)

系统化软件开发方法论。

**核心技能**: brainstorming, systematic-debugging, writing-plans, executing-plans, test-driven-development, requesting-code-review, receiving-code-review, verification-before-completion, using-superpowers, finishing-a-development-branch, dispatching-parallel-agents, subagent-driven-development, using-git-worktrees

## 2. code-review@claude-plugins-official

代码审查。`/code-review` 命令对当前 diff 做 correctness 检查。

## 3. github@claude-plugins-official

GitHub 集成。支持 PR 操作、issue 管理等。

## 4. skill-creator@claude-plugins-official

创建和管理自定义技能的框架。`/skill-creator` 创建新技能。

## 5. pua@pua-skills (v3.4.6)

高效能问题解决方法论。13 种企业文化风格，覆盖需求分析、架构设计、MVP 交付。

## 6. oh-my-claudecode@omc (v4.14.4)

增强型工作流和工具集。

**MCP 工具 (30+)**: ast_grep_search/replace, lsp_* (11个 LSP 工具), notepad_* (工作记忆), project_memory_*, shared_memory_*, wiki_*, state_*, python_repl

**Agent 类型 (32+)**: general-purpose, Explore, Plan, claude, claude-code-guide, brainstorming, systematic-debugging 等

**Hook**: PreToolUse, PostToolUse, PreCompact 等 36 个自动化钩子

## 7. claude-hud@claude-hud (v0.1.0)

终端状态栏。显示模型、token 使用、session 时间等。

启用: `/hud setup`
