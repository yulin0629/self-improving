#!/usr/bin/env bash
# init-learnings.sh — SessionStart hook
# Initializes .learnings/ in the current project directory if it does not exist.
# IMPORTANT: SessionStart hooks do not support additionalContext output; this script
# only performs side effects (directory creation + template copy).

set -euo pipefail

LEARNINGS_DIR=".learnings"

mkdir -p "$LEARNINGS_DIR"

for template in ERRORS.md LEARNINGS.md; do
  if [ ! -f "$LEARNINGS_DIR/$template" ]; then
    cp "${CLAUDE_PLUGIN_ROOT}/assets/$template" "$LEARNINGS_DIR/"
    echo "Copied $template to $LEARNINGS_DIR/"
  fi
done
