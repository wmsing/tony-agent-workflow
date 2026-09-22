---
name: llm-security-check
description: >-
  Audits a project's Cursor/LLM agent safety posture against OWASP LLM Top 10
  controls (permissions, hooks, rules, secrets, MCP). Use when the user says
  llm security check, LLM安全检查, cursor安全检查, agent安全, or after changing
  .cursor config. Orthogonal to project-preflight (git + cursorignore).
---

# LLM Security Check

对照 OWASP LLM Top 10（控制权 / 数据泄漏 / 供应链）检查 Cursor 配置是否纵深防御就绪。

**边界契约**：
- `project-preflight` 写「挡 git + 挡上下文」（`.gitignore` / `.cursorignore`）
- 本卡 `--apply` 写「CLI + **读密钥** hook + safety rule」；**不**写 shell HITL/ask；**不**写 `.cursorignore` / 不改 `.gitignore`
- Shell 危险命令交给全局 `agent-firewall`（或用户自行加 `block-dangerous-shell.sh`）
- 与 preflight **正交**

## When to run

- 用户点名「LLM安全检查」「cursor安全检查」「agent安全」
- 新机首次 / 新仓尚未做过 Agent 配置审计
- 改过 `.cursor`（hooks / cli / rules）之后
- 无全局 firewall、且即将让 Agent 动 shell / 读敏感路径之前

不作为 `project-preflight` 的强制步骤。缺 `.cursorignore` 时：提示先跑 `/project-preflight`，本卡可继续审计其余项。

## Procedure

1. 在项目根目录执行检查脚本（必须真实跑，不要凭记忆）：

```bash
bash ~/.cursor/skills/llm-security-check/scripts/check.sh
```

可选：补齐 **无弹窗** 纵深（不覆盖已有；**不写** `.cursorignore`；**不装** shell ask hook）：

```bash
bash ~/.cursor/skills/llm-security-check/scripts/check.sh --apply
```

`--apply` 仅可能新建：
- `.cursor/cli.json`（deny 读/写密钥 + 危险 shell；静默拒绝，非 ask 弹窗）
- `.cursor/hooks.json`（**仅** `beforeReadFile` → secret-read）
- `.cursor/hooks/block-secret-reads.sh`
- `.cursor/rules/llm-agent-safety.mdc`

**故意不装**：`beforeShellExecution` / `block-dangerous-shell.sh`（避免 npm/curl/push 弹 HITL）。

2. 按脚本输出的 `FAIL` / `WARN` / `PASS` 汇报。
3. 有 `FAIL`：先修复或 `--apply`（ignore 类 FAIL 则回 preflight），再继续依赖 Agent 的危险操作。
4. 有 `WARN`：列出风险，问用户是否忽略后继续。缺项目级 shell hook 为预期 WARN/PASS（默认靠 agent-firewall）。
5. 全部 `PASS`（或仅可接受 WARN）：一句话确认「LLM 安全基线通过」。

## Report format (mandatory)

```markdown
# LLM Security Check — <project>

Verdict: PASS | WARN | FAIL

| Check | Status | Note |
|-------|--------|------|
| ... | PASS/WARN/FAIL | ... |

Next actions:
- ...
```

## Do not

- 不要跳过脚本直接口头说「看起来安全」
- 不要用 `--apply` 覆盖用户已有自定义配置（脚本默认 skip-existing）
- 不要把真实 `.env` 内容读进上下文
- 不要要求先跑或嵌套执行 `project-preflight`（可提示；ignore 归对方）
- 不要用 `--apply` 写 `.cursorignore` 或改 `.gitignore`
- 不要用默认 `--apply` 再挂会 ask 弹窗的 shell hook

## Mapping (quick)

| Control | LLM# |
|---------|------|
| cli.json deny（静默） | LLM03 |
| .cursorignore（preflight）+ secret-read hook | LLM02 / LLM08 |
| always-apply safety rule | LLM01 / LLM10 |
| MCP / agent-firewall for shell | LLM03 / LLM04 |
| shell ask HITL | 默认不上；可选手工 |

详见 [checklist.md](checklist.md)。
