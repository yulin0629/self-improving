# self-improving Plugin

Claude Code plugin：自動 error detection + recurrence tracking + session-reflect。

## 架構

```
hooks/error-detector.sh    ← PostToolUse + PostToolUseFailure hook
skills/session-reflect/    ← 從 ~/.claude/skills/ 遷入，含 recurrence 整合
skills/pattern-scan/       ← 掃描 .learnings/ 並建議提升
assets/                    ← .learnings/ 初始模板
```

## 儲存

- 專案級 `.learnings/*.md`（跨 coding harness 共用）
- 提升目標：`~/.claude/rules/`（chezmoi 同步）

## 開發注意

- Hook 只輸出 stdout（stderr = Claude Code hook 錯誤）
- `error-detector.sh` 依賴 `jq`（fallback `python3`）
- Entry 格式定義在 `skills/pattern-scan/references/learnings-schema.md`
- Plugin 版號在 `.claude-plugin/plugin.json` 和 `.claude-plugin/marketplace.json`，兩處需同步更新

## 測試 hook

```bash
# PostToolUseFailure
echo '{"hook_event_name":"PostToolUseFailure","tool_name":"Bash","error":"command not found"}' | bash hooks/error-detector.sh

# PostToolUse with error pattern
echo '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_response":"fatal: bad object"}' | bash hooks/error-detector.sh

# PostToolUse clean (should produce no output)
echo '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_response":"ok"}' | bash hooks/error-detector.sh
```
