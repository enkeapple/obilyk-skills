#!/bin/bash
# Auto-lint the modified TypeScript/JavaScript file only
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx || "$FILE_PATH" == *.js || "$FILE_PATH" == *.jsx ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
  npx eslint --fix "$FILE_PATH" 2>/dev/null || true
fi
