#!/usr/bin/env bash
# Audit Cursor/LLM agent safety baseline for the current project.
# Usage: check.sh [--apply] [project_root]
set -euo pipefail

APPLY=0
ROOT=""
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *) ROOT="$arg" ;;
  esac
done

ROOT="${ROOT:-$(pwd)}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SKILL_DIR/templates"

pass=0
warn=0
fail=0

status() {
  local level="$1" msg="$2"
  case "$level" in
    PASS) pass=$((pass+1)); echo "[PASS] $msg" ;;
    WARN) warn=$((warn+1)); echo "[WARN] $msg" ;;
    FAIL) fail=$((fail+1)); echo "[FAIL] $msg" ;;
  esac
}

copy_if_missing() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "  skip (exists): $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  if [[ "$dest" == *.sh ]]; then
    chmod +x "$dest"
  fi
  echo "  wrote: $dest"
}

echo "LLM Security Check"
echo "project: $ROOT"
echo "--------"

# 1) cli.json deny
CLI="$ROOT/.cursor/cli.json"
if [[ -f "$CLI" ]]; then
  if python3 - "$CLI" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p))
deny=(d.get("permissions") or {}).get("deny") or []
need=[".env","rm","curl"]
text=" ".join(deny).lower()
missing=[n for n in need if n.lower() not in text]
sys.exit(1 if missing else 0)
PY
  then
    status PASS ".cursor/cli.json has deny coverage (.env / rm / curl)"
  else
    status FAIL ".cursor/cli.json exists but deny is too weak (need .env, rm, curl)"
  fi
else
  status FAIL "missing .cursor/cli.json"
fi

# 2) .cursorignore
IGNORE="$ROOT/.cursorignore"
if [[ -f "$IGNORE" ]]; then
  if grep -Eiq '\.env|secret|credentials|\.pem|\.key' "$IGNORE"; then
    status PASS ".cursorignore blocks secrets"
  else
    status WARN ".cursorignore exists but no obvious secret patterns"
  fi
else
  status FAIL "missing .cursorignore"
fi

# 3) hooks.json — secret-read required; shell HITL optional (no ask popups in default --apply)
HOOKS="$ROOT/.cursor/hooks.json"
if [[ -f "$HOOKS" ]]; then
  if grep -q 'beforeReadFile' "$HOOKS"; then
    status PASS "hooks.json has beforeReadFile"
  else
    status FAIL "hooks.json missing beforeReadFile (secret-read gate)"
  fi
  if grep -q 'beforeShellExecution' "$HOOKS"; then
    status WARN "hooks.json has beforeShellExecution (may HITL/ask on npm/curl/push; prefer agent-firewall)"
  else
    status PASS "no beforeShellExecution (shell HITL skipped; OK with agent-firewall)"
  fi
  if grep -q '"failClosed"[[:space:]]*:[[:space:]]*true' "$HOOKS"; then
    status PASS "at least one hook is failClosed"
  else
    status WARN "no failClosed:true — hook crashes may fail open"
  fi
else
  status FAIL "missing .cursor/hooks.json"
fi

READ_HOOK="$ROOT/.cursor/hooks/block-secret-reads.sh"
if [[ -f "$READ_HOOK" ]]; then
  if [[ -x "$READ_HOOK" ]]; then
    status PASS "block-secret-reads.sh is executable"
  else
    status FAIL "block-secret-reads.sh exists but is not executable"
  fi
else
  status FAIL "missing .cursor/hooks/block-secret-reads.sh"
fi

SHELL_HOOK="$ROOT/.cursor/hooks/block-dangerous-shell.sh"
if [[ -f "$SHELL_HOOK" ]]; then
  status WARN "block-dangerous-shell.sh present (shell gate; may ask on network/install/push)"
else
  status PASS "no block-dangerous-shell.sh (default --apply omits shell HITL)"
fi

# 4) always-apply safety rule
RULE_DIR="$ROOT/.cursor/rules"
if [[ -d "$RULE_DIR" ]] && grep -RIq 'alwaysApply:[[:space:]]*true' "$RULE_DIR" 2>/dev/null \
  && grep -RIqE 'HITL|\.env|secret|least privilege|最小权限|人工确认' "$RULE_DIR" 2>/dev/null; then
  status PASS "always-apply safety rule present"
else
  status FAIL "missing always-apply LLM safety rule under .cursor/rules/"
fi

# 5) gitignore secrets
GITIGNORE="$ROOT/.gitignore"
if [[ -f "$GITIGNORE" ]] && grep -Eiq '(^|/)\.env' "$GITIGNORE"; then
  status PASS ".gitignore covers .env"
else
  status WARN ".gitignore missing or does not cover .env"
fi

# 6) MCP inventory (presence only)
MCP_CFG=""
for c in "$ROOT/.cursor/mcp.json" "$ROOT/mcp.json" "$HOME/.cursor/mcp.json"; do
  if [[ -f "$c" ]]; then MCP_CFG="$c"; break; fi
done
if [[ -n "$MCP_CFG" ]]; then
  status WARN "MCP config found at $MCP_CFG — manually review tool allowlist (LLM04)"
else
  status PASS "no project/user mcp.json detected in common paths (or not required)"
fi

echo "--------"
echo "summary: PASS=$pass WARN=$warn FAIL=$fail"

if [[ "$APPLY" -eq 1 ]]; then
  echo "--------"
  echo "applying lean templates (no shell HITL/ask; skip existing; ignore owned by project-preflight)..."
  copy_if_missing "$TPL/.cursor/cli.json" "$ROOT/.cursor/cli.json"
  copy_if_missing "$TPL/.cursor/hooks.json" "$ROOT/.cursor/hooks.json"
  copy_if_missing "$TPL/.cursor/hooks/block-secret-reads.sh" "$ROOT/.cursor/hooks/block-secret-reads.sh"
  copy_if_missing "$TPL/.cursor/rules/llm-agent-safety.mdc" "$ROOT/.cursor/rules/llm-agent-safety.mdc"
  chmod +x "$ROOT/.cursor/hooks/"*.sh 2>/dev/null || true
  echo "  skip: block-dangerous-shell.sh / beforeShellExecution (no ask popups; use agent-firewall for shell)"
  if [[ ! -f "$ROOT/.cursorignore" ]]; then
    echo "  note: missing .cursorignore — create via /project-preflight (not --apply)"
  fi
  echo "re-run without --apply to verify."
fi

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
if [[ "$warn" -gt 0 ]]; then
  exit 0
fi
exit 0
