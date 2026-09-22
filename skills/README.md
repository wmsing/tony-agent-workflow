# Cursor Agent 工作流 Skills

Personal Cursor Agent workflow: `/tonysing` entry, one-shot project preflight, and OWASP-style `llm-security-check` skills.

**现在就做（约 3 分钟）**

1. 克隆：`git clone <本仓库 URL> ~/repos/tony-agent-workflow`
2. 三条软链（复制整段执行）：

```bash
ln -sf ~/repos/tony-agent-workflow/skills/tonysing ~/.cursor/skills/tonysing
ln -sf ~/repos/tony-agent-workflow/skills/project-preflight ~/.cursor/skills/project-preflight
ln -sf ~/repos/tony-agent-workflow/skills/llm-security-check ~/.cursor/skills/llm-security-check
```

3. 新开 Cursor 对话，输入 **`/tonysing`** — 出现提醒卡即安装成功。

不想软链？`cp -R ~/repos/tony-agent-workflow/skills/* ~/.cursor/skills/` 也行，但以后更新要再复制一次。

---

**只记一句**

日常忘了用啥 → 对话里打 **`/tonysing`**。

---

**三种情况 → 打什么**

| 你现在在… | 输入 |
|-----------|------|
| 新仓库 / 新模块，还没开工检查 | `project-preflight` |
| 要让 Agent 大量读文件或跑 shell | `llm-security-check`（项目根：`bash ~/.cursor/skills/llm-security-check/scripts/check.sh`） |
| 其它（写码、方案、忘了） | `/tonysing` |

`ponytail`、`ask-matt`、`archify` 不在本仓；`/tonysing` 会指路。

---

**本仓三个目录**

1. **tonysing** — 入口提醒卡 + 分流（需你主动 `/tonysing`）
2. **project-preflight** — 一次：`.gitignore`、`.cursorignore`、极简规则、跑通最小测试
3. **llm-security-check** — 审计 Cursor 配置；要落盘加：`check.sh --apply`

---

**细节（不用先读）**

- **preflight** 管：密钥别进 git / 别进 Agent 上下文（ignore）。
- **security-check --apply** 管：CLI 拒绝读密钥、`beforeReadFile` hook、安全 rule。不写 ignore。
- 二者分开做，不互相强制。缺 ignore 时 security 会叫你先 preflight。

```text
/tonysing → 新项目？→ project-preflight →（可选）llm-security-check
```

目录树：`tonysing/`、`project-preflight/`、`llm-security-check/`（含 `scripts/check.sh`、`templates/`）。

个人工作流快照；fork 后改 `<本仓库 URL>` 与外部 skill 列表即可。
