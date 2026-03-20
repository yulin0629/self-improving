#!/usr/bin/env bash
# error-detector.sh — PostToolUse / PostToolUseFailure hook
# Detects Bash errors and injects additionalContext for the AI.
# IMPORTANT: All output goes to stdout only (stderr = hook error in Claude Code).

set -euo pipefail

# Read stdin JSON
INPUT=$(cat)

# Extract a top-level field from the input JSON
extract_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r ".$field // empty"
  else
    python3 -c "import sys,json; d=json.loads(sys.stdin.read()); v=d.get('$field',''); print(v if isinstance(v,str) else json.dumps(v))" <<< "$INPUT"
  fi
}

HOOK_EVENT=$(extract_field "hook_event_name")
TOOL_NAME=$(extract_field "tool_name")

# Only process Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# The context message to inject (as plain text)
CONTEXT_MSG="A command error was detected. If this was unexpected or required investigation:
1. Log to .learnings/ERRORS.md with pattern-key for recurrence tracking
2. If similar to an existing entry, update recurrence count instead of creating new
3. Use /self-improving:pattern-scan to check existing patterns"

# JSON-encode a string safely
json_encode() {
  python3 -c "import json,sys; print(json.dumps(sys.stdin.read().strip()))" <<< "$1"
}

emit_context() {
  local event_name="$1"
  local encoded
  encoded=$(json_encode "$CONTEXT_MSG")
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":%s}}\n' "$event_name" "$encoded"
}

# --- PostToolUseFailure path: always trigger ---
if [ "$HOOK_EVENT" = "PostToolUseFailure" ]; then
  emit_context "PostToolUseFailure"
  exit 0
fi

# --- PostToolUse path: check for error patterns in tool_response ---
if [ "$HOOK_EVENT" = "PostToolUse" ]; then
  # Extract tool_response as string for pattern matching
  RESPONSE=""
  if command -v jq >/dev/null 2>&1; then
    RESPONSE=$(echo "$INPUT" | jq -r 'if .tool_response | type == "string" then .tool_response elif .tool_response then (.tool_response | tostring) else "" end' 2>/dev/null || true)
  else
    RESPONSE=$(python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
r = d.get('tool_response', '')
print(r if isinstance(r, str) else json.dumps(r))
" <<< "$INPUT" 2>/dev/null || true)
  fi

  [ -z "$RESPONSE" ] && exit 0

  # High-precision error patterns (case-insensitive check)
  PATTERNS=(
    "fatal:"
    "Traceback (most recent"
    "command not found"
    "Permission denied"
    "No such file or directory"
    "SyntaxError:"
    "ModuleNotFoundError:"
    "ImportError:"
    "ENOENT:"
    "EACCES:"
  )

  for pattern in "${PATTERNS[@]}"; do
    if echo "$RESPONSE" | grep -qi "$pattern" 2>/dev/null; then
      emit_context "PostToolUse"
      exit 0
    fi
  done
fi
