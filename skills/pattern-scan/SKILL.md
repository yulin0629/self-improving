---
name: pattern-scan
description: >-
  Scans .learnings/ entries for recurring error patterns and suggests promotions.
  Use when: "scan patterns", "check recurrence", "review learnings", "promote learnings",
  "掃描 pattern", "檢查重複", "查看學習記錄", or after logging an error to .learnings/.
---

# Pattern Scan

掃描專案 `.learnings/` 目錄中的記錄，追蹤 recurrence，達閾值建議提升。

## 前置條件

確認專案根目錄有 `.learnings/` 目錄。沒有的話，從 plugin assets 複製模板：

```bash
mkdir -p .learnings
cp "${CLAUDE_PLUGIN_ROOT}/assets/LEARNINGS.md" .learnings/LEARNINGS.md
cp "${CLAUDE_PLUGIN_ROOT}/assets/ERRORS.md" .learnings/ERRORS.md
```

若 `${CLAUDE_PLUGIN_ROOT}` 不可用，直接建立空模板（見 assets/ 內容）。

## 記錄指南

當 AI 遇到值得記錄的錯誤或學習時：

1. 確認 `.learnings/` 存在
2. 從錯誤/學習中提取 Pattern-Key（格式：`<namespace>.<descriptive-name>`）
3. 用 Grep 搜尋 `.learnings/*.md` 是否已有相同 Pattern-Key
4. **已存在**：increment Recurrence-Count + update Last-Seen + 若有更好解法則更新 Fix
5. **不存在**：append 新 entry 到對應檔案（ERRORS.md 或 LEARNINGS.md）

Entry 格式參考：`references/learnings-schema.md`

## Scan Workflow

執行掃描時：

### Step 1 — 收集 entries

讀取當前專案 `.learnings/*.md` 中所有 entries，解析每筆的：
- ID、Pattern-Key、Recurrence-Count、Status、First-Seen、Last-Seen

### Step 2 — 分析 recurrence

| 狀態 | 條件 | 動作 |
|------|------|------|
| 已提升 | Status: promoted | 跳過（已處理） |
| 建議提升 | Recurrence-Count >= 3 且 First-Seen != Last-Seen | 列為提升候選 |
| 累積中 | Recurrence-Count < 3 | 僅顯示狀態 |

### Step 3 — 呈現結果

輸出摘要表：

```
| Pattern-Key | Count | First | Last | Status |
|-------------|-------|-------|------|--------|
| git.ssh-agent-missing | 4 | 03-15 | 03-20 | 建議提升 |
| shell.bsd-sed-syntax | 2 | 03-18 | 03-19 | 累積中 |
```

### Step 4 — 提升流程

對每個「建議提升」的 entry，用 AskUserQuestion 逐一確認：

提供選項：
1. **提升到 `~/.claude/rules/<topic>.md`** — 通用規則（chezmoi 同步到其他機器）
2. **提升到 skill reference** — 工具特定知識
3. **暫不提升** — 繼續累積
4. **標記為已知** — 不再建議提升

使用者確認後：
1. 寫入目標位置
2. 更新 entry 的 Status 為 `promoted`，加上 `Promoted: <target-path>`
3. 若目標在 chezmoi 管理範圍內，執行 `chezmoi re-add`

## 與 session-reflect 的關係

同一 plugin 內，`/self-improving:session-reflect` 在路由修正前會先查 `.learnings/` 中的 Pattern-Key。pattern-scan 則是獨立的定期掃描工具。

兩者互補：
- **session-reflect** — 即時捕捉，逐筆路由
- **pattern-scan** — 定期總覽，批次提升
