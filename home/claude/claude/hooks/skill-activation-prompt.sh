#!/usr/bin/env bash
set -e

cd "$CLAUDE_CONFIG_DIR/hooks"
cat | npx tsx skill-activation-prompt.ts
