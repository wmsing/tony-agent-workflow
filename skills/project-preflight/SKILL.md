---
name: project-preflight
description: >-
  跨语言通用的新项目/新模块工程开工流水线（挡 git + 挡上下文、自适应规则、验证闭环、Plan破冰）。
  当用户提到“项目初始化”、“开工检查”、“新项目开始”、“preflight”、“初始化规则”时使用。
  不写 CLI/hooks（见 llm-security-check --apply）。
---

# 跨语言项目开工 Preflight

严禁在执行完以下 4 步前直接编写业务代码。

**边界契约**：本卡写「挡 git + 挡上下文」；`/llm-security-check --apply` 写「CLI + hooks 纵深」。二者正交，互不嵌套强制执行。

## 1. 挡 git + 挡上下文（Sensitive files）

- 检查是否存在未加进 `.gitignore` 的敏感配置文件（`.env*`、`*key*`、`*.pem`、`credentials*`）。有泄漏风险则先提醒用户，严禁直接写业务。
- **本卡负责写入（缺则补、已有则跳过，不覆盖）**：
  1. `.gitignore`：确保含 `.env` / `.env.*`（可保留 `!.env.example`）。
  2. `.cursorignore`：缺则从  
     `~/.cursor/skills/llm-security-check/templates/.cursorignore`  
     拷贝到项目根（把密钥挡在 Agent 上下文外）。
- **本卡不写**：`.cursor/cli.json`、`hooks.json`、`block-*.sh`（留给 `/llm-security-check --apply`）。

## 2. 自适应常驻规则检查（Universal Rules）
- 检查是否存在 `.cursor/rules/`。若无，在根目录创建极简 `.cursor/rules/project.md`（控制在 30 行内）：
  - **核心命令**：根据项目语言类型（Node/Python/Go/Rust/Java/C++）自适应填入：构建、类型检查/Lint、单测执行命令。
  - **绝对禁区**：禁止擅改 `.env*`、生产配置与数据库迁移文件；禁止把密钥读进上下文或提交。
  - **规范准则**：代码风格交给格式化工具，规则内仅留 1 个核心范例文件的相对路径（仅留路径，不复制代码）。

## 3. 验证本地反馈闭环（Verifiable Goals）
- 在终端跑通当前语言的“最小验证套件”（至少跑通一次 Typecheck 或 Test）。
- **原则**：Agent 无法修复它看不见的错误。若当前项目完全没有测试环境，优先提示或协助用户建立首个极简测试文件。

## 4. 破冰启动（Start in Plan Mode）
- 引导用户开启新对话，按下 `Shift + Tab` 切换至 **Plan Mode**。
- **首条 Prompt 指引**：
  > "请先探索代码库并给出 [功能目标] 的 Markdown 方案，列出受影响的文件和测试策略。方案获得批准前，不要动任何代码。"

## 可选（不执行）

- CLI + 读密钥 hook + safety（`cli.json` / `beforeReadFile` / `llm-agent-safety.mdc`）→ 另开 `/llm-security-check`（可加 `--apply`；**默认不装** shell ask 弹窗）。
- 有全局 `agent-firewall`：管 shell；本卡仍必须落 ignore。
