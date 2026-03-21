#!/usr/bin/env bash
# init-learnings.sh — SessionStart hook
# Initializes .learnings/ in the current project directory if it does not exist.
# IMPORTANT: SessionStart hooks do not support additionalContext output; this script
# only performs side effects (directory creation + template copy).

set -euo pipefail

LEARNINGS_DIR=".learnings"

if [ ! -d "$LEARNINGS_DIR" ]; then
  mkdir -p "$LEARNINGS_DIR"
  cp "${CLAUDE_PLUGIN_ROOT}/assets/ERRORS.md" "$LEARNINGS_DIR/"
  cp "${CLAUDE_PLUGIN_ROOT}/assets/LEARNINGS.md" "$LEARNINGS_DIR/"
  echo "Initialized $LEARNINGS_DIR/ from plugin templates"
fi
