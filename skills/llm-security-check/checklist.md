# LLM Security Check — detailed checklist

## Ownership

| Artifact | Owner |
|----------|--------|
| `.gitignore` (`.env`) + `.cursorignore` | `project-preflight`（写） |
| `.cursor/cli.json`, `hooks.json`（仅 Read）、`block-secret-reads.sh`, `llm-agent-safety.mdc` | `llm-security-check --apply`（写） |
| `beforeShellExecution` / `block-dangerous-shell.sh` | **默认不装**（避 ask 弹窗）；shell 靠 agent-firewall 或手工加 |

本检查仍可对 `.cursorignore` / `.gitignore` 报 FAIL/WARN（验有无），但 **`--apply` 不创建它们**。

## FAIL if missing

1. `.cursor/cli.json` with non-empty `permissions.deny` covering secrets (and preferably destructive shell)
2. `.cursorignore` — **fix via preflight**, do not `--apply` here
3. `.cursor/hooks.json` with `beforeReadFile` (secret-read gate)
4. Executable `block-secret-reads.sh`
5. Always-apply rule that bans secret reads / irreversible ops without confirmation

## WARN if missing / weak

1. `.env` in `.gitignore` — **fix via preflight**
2. MCP allowlist review（刻意接入的 `agent-firewall` 可接受）
3. `beforeShellExecution` / `block-dangerous-shell.sh` **存在**时提醒：可能对 npm/curl/push **ask 弹窗**
4. 无 `failClosed: true` on secret-read hook

## PASS note

缺项目级 shell HITL hook → **PASS/预期**（默认 `--apply` 省略；用全局 firewall 管 shell）。

## PASS criteria

All FAIL items present and coherent; WARN items either present or explicitly accepted by user.
