# .learnings/ Entry Schema

每筆 entry 使用以下格式。`Pattern-Key` 和 `Recurrence-Count` 為必填欄位。

## Entry Format

```markdown
## [ERR-YYYYMMDD-NNN] short_title

**Logged**: YYYY-MM-DD
**Priority**: low | medium | high
**Status**: pending | promoted
**Pattern-Key**: <namespace>.<descriptive-name>
**Recurrence-Count**: <number>
**First-Seen**: YYYY-MM-DD
**Last-Seen**: YYYY-MM-DD
**Promoted**: <target-path>  ← 僅 Status: promoted 時填寫

### Summary

簡要描述問題（1-3 句）

### Fix

解決方式或 workaround

---
```

## 欄位說明

| 欄位 | 必填 | 說明 |
|------|------|------|
| ID | 是 | `[ERR-YYYYMMDD-NNN]` 或 `[LRN-YYYYMMDD-NNN]`（ERR = error, LRN = learning） |
| short_title | 是 | snake_case 簡短標題 |
| Logged | 是 | 首次記錄日期 |
| Priority | 是 | `low`（偶發/低影響）、`medium`（中頻/中影響）、`high`（高頻/高影響） |
| Status | 是 | `pending`（等待累積）或 `promoted`（已提升到永久位置） |
| Pattern-Key | 是 | `<namespace>.<name>` 格式，用於 recurrence 比對。namespace 建議：`git`、`shell`、`npm`、`python`、`docker`、`api`、`config`、`test` |
| Recurrence-Count | 是 | 此 pattern 出現次數，初始為 1 |
| First-Seen | 是 | 首次出現日期 |
| Last-Seen | 是 | 最近出現日期 |
| Promoted | 否 | 提升目標路徑（僅 promoted 時填） |
| Summary | 是 | 問題描述 |
| Fix | 是 | 解決方式 |

## Pattern-Key 命名規範

格式：`<namespace>.<descriptive-name>`

- namespace 從固定清單選（見上方表格），保持一致性
- descriptive-name 用 kebab-case
- 要足夠具體以區分不同問題，但不要太具體以至於相似問題無法合併

**範例：**
- `git.ssh-agent-missing` — SSH agent 未啟動導致 push 失敗
- `shell.bsd-sed-syntax` — macOS BSD sed 語法與 GNU 不同
- `npm.peer-dep-conflict` — npm 安裝時 peer dependency 衝突
- `python.venv-not-activated` — 未啟用虛擬環境導致 import 失敗
- `config.env-var-missing` — 缺少必要的環境變數

## 提升閾值

當 `Recurrence-Count >= 3` 且跨越不同日期（非同一 session 內連續失敗）時，建議提升到永久位置：

- `~/.claude/rules/<topic>.md` — 通用規則
- skill 的 reference 文件 — 工具特定知識
