#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit): block edits to security-critical files.
# Denies modifications to .claude/settings + .claude/hooks and sensitive config (secrets, keystores, .env).
# Exit codes: 2 = block (message on stderr); 0 = allow. Fails open on missing jq / unparseable stdin / empty path.
INPUT=$(cat -)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if printf '%s' "$FILE" | grep -qiE '\.(claude/(settings|hooks))|google-services\.json|GoogleService-Info\.plist|\.xcconfig|sentry\.properties|keystore|gradle\.properties|(^|/)\.env(\.|$)'; then
  echo "BLOCKED: Cannot modify security hooks, settings, or sensitive config files." >&2
  exit 2
fi
