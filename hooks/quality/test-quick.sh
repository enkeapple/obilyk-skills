#!/bin/bash
# Run only tests related to the changed file after TypeScript/JavaScript code changes
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx || "$FILE_PATH" == *.js || "$FILE_PATH" == *.jsx ]] && [[ "$FILE_PATH" != *.test.* ]] && [[ "$FILE_PATH" != *.spec.* ]] && [[ "$FILE_PATH" != *__tests__* ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
  npx jest --findRelatedTests "$FILE_PATH" --passWithNoTests 2>/dev/null || true
fi
