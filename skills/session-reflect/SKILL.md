---
name: session-reflect
description: Use when user says "回顧修正", "整理 feedback", "session reflect", or wants to review current session corrections and update skills, rules, or memory.
---

# Session Reflect

回顧當前對話中的修正與回饋，更新到對應檔案。

## 修正訊號

以下對話模式視為可提取的修正：

| 訊號 | 範例 |
|------|------|
| 否定 + 替代方案 | 「不要...，改用...」「別再...」「應該用...而不是...」 |
| 重複糾正同一行為 | 同一 session 內第二次以上的相同修正 |
| 明確偏好表達 | 「我比較喜歡...」「以後都用...」 |
| 驚訝/不滿反饋 | 「為什麼會...」「這不對吧」「你是不是不知道...」 |
| 平台行為澄清 | 使用者指出工具/API 的實際行為與 AI 假設不同 |
| 效率/品質不滿 | 「太長了」「太囉嗦」「不需要這麼多解釋」 |
| workflow 修正 | 「先做 A 再做 B，不要反過來」「以後遇到這種先問我」 |
| 自我修正 | 「等等，剛才那個不對，應該是...」 |
| 隱性規範 | 「我們團隊的慣例是...」「公司規定要...」 |
| skill 執行修正 | 照 skill 指示操作出錯，查明原因並修正成功 |
| 隱性 workaround | AI 照 skill 範例指令執行失敗，改用不同寫法成功（即使使用者未明確指出） |

偵測提示：掃描時主動比對「skill 提供的範例指令」與「AI 實際成功執行的指令」，若寫法不同且 skill 版本會導致失敗，視為 skill 需要修正。

不視為修正：一次性任務指示、單純 context 補充、對結果的確認、開玩笑/吐槽、對第三方的抱怨。

## 流程

1. 掃描當前對話，**兩個維度都要掃**：
   - **使用者的明確修正**：依修正訊號表找出使用者指出的問題
   - **AI 自身的靜默失敗**：找出 AI 執行失敗後靜默繞過的指令（隱性 workaround），即使使用者沒提到。具體做法：列出對話中所有失敗的工具呼叫 → 比對成功的替代方案 → 判斷是否需要更新 skill
2. 若無修正，告知使用者並詢問是否有遺漏想手動補充
3. 合併指向同一檔案同一段落的修正
4. **Recurrence 檢查（.learnings/ 整合）**：
   - 對每筆識別到的修正，提取可能的 Pattern-Key（如 `git.ssh-agent-missing`、`shell.bsd-sed-syntax`）
   - 用 Grep 搜尋當前專案 `.learnings/*.md` 中是否有相同 Pattern-Key
   - **找到匹配**：
     - 更新該 entry 的 Recurrence-Count + 1
     - 更新 Last-Seen 為今天
     - 若這次修正有更好的解法或更完整的描述，同時更新 Fix section
     - 此筆修正**仍繼續走路由流程**（recurrence 追蹤與路由是獨立的）
   - **未找到匹配**：在 `.learnings/` 中建立新 entry（若 `.learnings/` 目錄存在），然後繼續路由
   - **`.learnings/` 不存在**：跳過 recurrence 檢查，直接進路由
   - 若某筆 entry 的 Recurrence-Count >= 3 且 First-Seen != Last-Seen：在步驟 7 呈現時特別標註「建議提升到 ~/.claude/rules/」
5. 根據上下文判斷建議目標（見路由建議）
6. 檢查建議目標檔案是否已有相同或相似規則（有則更新，無則新增）
7. 呈現修正讓使用者確認（見呈現格式）
8. **驗證根因**：寫入 skill 前，必須實際重現失敗場景確認根因，不可猜測原因就寫入
9. 使用者確認後寫入 + chezmoi re-add（僅限 chezmoi 管理的檔案）

## 路由建議

根據修正發生的上下文判斷建議目標：

| 上下文 | 建議目標 | 範例 |
|--------|---------|------|
| 使用特定 skill 過程中的錯誤 | 改善該 skill | 路由錯誤 → 更新 `skills/session-reflect/SKILL.md` |
| 工具使用知識（CLI flag、API 行為） | 對應 skill 的 reference 文件 | `mcp list` 不支援 scope → `skills/claude-code-expert/references/mcp-plugins.md` |
| slash command 行為修正 | `~/.claude/commands/` 對應檔案 | `/commit` 少了 session trace → 更新 command |
| 一般性行為約束 | `~/.claude/rules/<topic>.md` | 部署前先測試 → `rules/deployment.md` |
| 專案特定的行為約束 | project `.claude/rules/<topic>.md` | MCP URL 格式 → `.claude/rules/openai-realtime-docs.md` |
| 專案特定的修正 | project scope CLAUDE.md | 此專案用 gpt-5-mini → `.claude/CLAUDE.md` |
| 使用者偏好/個人風格 | auto memory（feedback type） | 「回覆簡短一點」→ memory |

判斷提示：當規則內容包含專案特有的檔案路徑、結構、或工具設定時，應路由到 project rules 而非 global rules。

### Rules 的 paths 條件

Rules 支援 `paths` YAML frontmatter（glob pattern），只在 Claude 讀取匹配檔案時才載入。若規則只跟特定檔案類型相關，加上 `paths` 可節省 context。

多目標同時適用時，採「最具體優先」：skill > skill reference > commands > global rules > project rules > CLAUDE.md > memory。

## 呈現格式

每筆 learning 用 AskUserQuestion 呈現，包含：

- **原文摘要**：使用者說了什麼（引用對話原文）
- **建議規則**：提煉出的規則文字（preview）
- **建議目標**：根據路由建議預選的目標
- **Recurrence 狀態**：若在 `.learnings/` 中有匹配，顯示 Pattern-Key 和目前 Count

呈現策略：
- 3 筆以下：逐筆確認
- 4 筆以上：先列摘要表，使用者可批次確認或逐筆審閱

目標選項：

1. 對應 skill / skill reference 文件
2. `~/.claude/commands/` 對應檔案
3. `~/.claude/rules/<topic>.md`（global，新建或追加）
4. project `.claude/rules/<topic>.md`（project scope，新建或追加）
5. `~/.claude/CLAUDE.md`（user scope）
6. 專案 CLAUDE.md（project scope）
7. auto memory（feedback type）
8. 跳過
