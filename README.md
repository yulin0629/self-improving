# self-improving

Claude Code plugin for automatic error detection and recurring pattern tracking.

## Features

- **Error Detection Hook** — Automatically detects Bash command failures and injects context for the AI to log them
- **Recurrence Tracking** — Tracks recurring error patterns via `.learnings/` directory with Pattern-Key matching
- **Promotion Threshold** — Suggests promoting frequently recurring patterns (count >= 3) to permanent rules
- **Session Reflect** — Reviews session corrections and routes learnings to appropriate targets

## Skills

| Skill | Description |
|-------|-------------|
| `/self-improving:session-reflect` | Review current session corrections and update skills, rules, or memory |
| `/self-improving:pattern-scan` | Scan `.learnings/` entries for recurring patterns and suggest promotions |

## Storage

Project-level `.learnings/` directory (cross-tool compatible):

```
<project-root>/
└── .learnings/
    ├── LEARNINGS.md    # Corrections, knowledge gaps, best practices
    └── ERRORS.md       # Command failures, exceptions
```

## Installation

Add to `~/.claude/plugins/known_marketplaces.json`:

```json
"self-improving-local": {
  "source": {
    "source": "directory",
    "path": "/path/to/self-improving"
  }
}
```

Then install:

```
claude plugin install self-improving@self-improving-local
```
