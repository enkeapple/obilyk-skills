#!/usr/bin/env bash
INPUT=$(cat -)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if printf '%s' "$FILE" | grep -qiE '\.(claude/(settings|hooks))|google-services\.json|GoogleService-Info\.plist|\.xcconfig|sentry\.properties|keystore|gradle\.properties|(^|/)\.env(\.|$)'; then
  echo "BLOCKED: Cannot modify security hooks, settings, or sensitive config files." >&2
  exit 2
fi
