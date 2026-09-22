---
name: tonysing
description: >-
  Tony 干活入口与忘了就来的提醒卡。用户说 tonysing、/tonysing、忘了、该用哪个、
  下一步是什么、不知道从哪开始时使用。先提醒再分流到 project-preflight /
  ponytail / ask-matt / archify。
disable-model-invocation: true
---

# /tonysing

**本卡 = 干活入口。** 忘了就打 `/tonysing`。Agent 必须先提醒，再分流。

## 每次调用：先贴提醒卡（强制）

回复**第一块**必须是下面这张卡（可原样或略压缩，不可省略）：

```text
【tonysing 提醒】
1. 新项目/新模块？→ 先 /project-preflight（只一次）→ 再回来干活
2. 日常写码要极简？→ ponytail
3. 拆方案/出票/实现/评审/修怪 bug？→ ask-matt
4. 要架构图/流程图/时序图？→ archify
5. 只记一个入口：/tonysing
```

## 然后分流

| 情况 | 动作 |
|---|---|
| 用户已说清要做什么 | 一行点名目标 skill → **立刻 Read 其 `SKILL.md` 并执行** |
| 用户只打了 `/tonysing` /「忘了」 | 贴完提醒卡后，用**一个问题**问：新项目 / 写码 / 工程流程 / 画图？ |
| 新项目且未做过工程开工检查 | 优先读并执行 `project-preflight`，不要直接写业务 |
| 用户点名 Agent 配置审计 / LLM 安全 | 读并执行 `llm-security-check`（与 preflight 正交，非提醒卡必选项） |

## 条件软提醒（勿写入固定 5 条卡）

当本仓**已做过** `project-preflight`，且未见 `.cursor/cli.json` 或 `.cursor/hooks/`（或用户明确说新仓刚 preflight 完）时：在提醒卡之后、分流问题之前，**多贴一行**（可略压缩）：

```text
CLI+读密钥纵深尚未落 → 可选 /llm-security-check（可 --apply，默认无 shell 弹窗）；有全局 firewall 仍建议至少验 ignore/Read 门禁。
```

- 不塞进固定提醒卡第 6 条；不因此强制执行 `llm-security-check`。
- 用户回「做安全检查 / llm-check」→ 再 Read 并执行该 skill。

禁止把 Matt / Ponytail / Archify 正文粘进本卡或本对话；只指路并加载对应文件。

## 叠用（提醒用）

- 写功能：`ponytail` 开着 → 大活再进 `ask-matt`
- 先想清楚：`ask-matt` → 实现时仍 `ponytail`
- 给人看：`archify` 出图（图 ≠ 代码）

## 冲突

1. 安全 / 密钥 / 不可逆 → 仓库安全规则优先  
2. 用户点名某 skill → 听用户  
3. 其余 → 上表  

## 完成标准

提醒卡已贴出 +（已分流并开始执行目标 skill，或已用一个问题等用户选）。
