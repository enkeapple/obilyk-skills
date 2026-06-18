#!/bin/bash
# Bash Read Guard — blocks shell commands that read sensitive files
# Runs as PreToolUse hook on Bash tool
# Exit codes: 0 = allow, 2 = block
# NOTE: best effort — obfuscated commands (eval, variables, c"a"t) can bypass this

INPUT=$(cat -)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# Sensitive path patterns — keep in sync with read-guard.sh (which uses individual checks for specific error messages)
SENSITIVE='(\.ssh/|\.aws/(credentials|config)|\.config/gcloud/(application_default|credentials\.db|access_tokens)|\.config/gh/hosts\.yml|\.config/hub|\.kube/config|\.netrc|\.docker/config\.json|\.npmrc|\.yarnrc|\.gnupg/private-keys|\.tfstate|\.vault[-_]token|service[-_.]account.*\.json|keystore\.jks|\.keystore|\.p12\b|\.pem\b|\.key\b|google-services\.json|GoogleService-Info\.plist|\.xcconfig|sentry\.properties|gradle\.properties|release-signing\.properties|\.env(\.|$|/))'

# Block commands that read/copy sensitive files
if printf '%s' "$CMD" | grep -qiE "(cat|less|more|head|tail|bat|xxd|base64|od|strings|cp|mv|tee|dd|tar|zip|gzip|zcat|file|wc|nl|sort|uniq|diff|hexdump)\s.*$SENSITIVE"; then
    echo "BLOCKED: Command attempts to read/copy sensitive credential files." >&2
    exit 2
fi

# Block source/dot-sourcing sensitive files
if printf '%s' "$CMD" | grep -qiE "(source|\.\s+).*$SENSITIVE"; then
    echo "BLOCKED: Command sources sensitive credential file." >&2
    exit 2
fi

# Block awk/sed/grep reading sensitive files (data extraction)
if printf '%s' "$CMD" | grep -qiE "(awk|sed|grep|rg|ag|perl)\s.*$SENSITIVE"; then
    echo "BLOCKED: Command reads sensitive credential file via text processor." >&2
    exit 2
fi

# Block find/xargs/locate targeting sensitive paths
if printf '%s' "$CMD" | grep -qiE "(find|locate|xargs|fd)\s.*$SENSITIVE"; then
    echo "BLOCKED: Command searches/pipes sensitive credential paths." >&2
    exit 2
fi

# Block redirects from sensitive files
if printf '%s' "$CMD" | grep -qiE "<\s.*$SENSITIVE"; then
    echo "BLOCKED: Command redirects from sensitive credential file." >&2
    exit 2
fi

# Block opening sensitive files with editors
if printf '%s' "$CMD" | grep -qiE "(vim|vi|nano|code|open|subl|emacs)\s.*$SENSITIVE"; then
    echo "BLOCKED: Command opens sensitive credential file." >&2
    exit 2
fi

# Block globbing into sensitive dirs
if printf '%s' "$CMD" | grep -qiE "(ls|dir|stat|file)\s+(-[a-zA-Z]*\s+)*.*\.ssh/|\.aws/|\.config/gcloud/|\.gnupg/"; then
    echo "BLOCKED: Command lists contents of sensitive directory." >&2
    exit 2
fi

exit 0