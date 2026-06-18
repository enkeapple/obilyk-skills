#!/bin/bash
# Read Guard Hook — blocks reading sensitive credential files
# Runs as PreToolUse hook on Read tool
# Exit codes: 0 = allow, 2 = block

INPUT=$(cat -)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# NOTE: bash-read-guard.sh uses a single combined regex for the same paths.
# This file uses individual checks for specific error messages per file type.

# Skip if no file path
[ -z "$FILE" ] && exit 0

# Block entire .ssh/ directory
if printf '%s' "$FILE" | grep -qiE '\.ssh/'; then
    echo "BLOCKED: Reading .ssh/ is forbidden. SSH keys must never be read by AI agent." >&2
    exit 2
fi

# Block GCP credentials
if printf '%s' "$FILE" | grep -qiE '(\.config/gcloud/(application_default_credentials|credentials\.db|access_tokens|properties)|service[-_.]account.*\.json)'; then
    echo "BLOCKED: Reading GCP credential files is forbidden." >&2
    exit 2
fi

# Block AWS credentials
if printf '%s' "$FILE" | grep -qiE '\.aws/(credentials|config)'; then
    echo "BLOCKED: Reading AWS credential files is forbidden." >&2
    exit 2
fi

# Block .env files anywhere (home, project, tmp)
if printf '%s' "$FILE" | grep -qiE '(^|/)\.env(\.|$)'; then
    echo "BLOCKED: Reading .env files is forbidden (may contain secrets)." >&2
    exit 2
fi

# Block kube config
if printf '%s' "$FILE" | grep -qiE '\.kube/config'; then
    echo "BLOCKED: Reading Kubernetes config is forbidden." >&2
    exit 2
fi

# Block .netrc
if printf '%s' "$FILE" | grep -qiE '\.netrc'; then
    echo "BLOCKED: Reading .netrc is forbidden." >&2
    exit 2
fi

# Block Docker config (registry tokens)
if printf '%s' "$FILE" | grep -qiE '\.docker/config\.json'; then
    echo "BLOCKED: Reading Docker config is forbidden (may contain registry tokens)." >&2
    exit 2
fi

# Block NPM/Yarn tokens
if printf '%s' "$FILE" | grep -qiE '\.(npmrc|yarnrc)'; then
    echo "BLOCKED: Reading npm/yarn config is forbidden (may contain auth tokens)." >&2
    exit 2
fi

# Block GPG private keys
if printf '%s' "$FILE" | grep -qiE '\.gnupg/private-keys'; then
    echo "BLOCKED: Reading GPG private keys is forbidden." >&2
    exit 2
fi

# Block Terraform state (contains secrets in plain text)
if printf '%s' "$FILE" | grep -qiE '\.tfstate'; then
    echo "BLOCKED: Reading Terraform state is forbidden (contains secrets in plain text)." >&2
    exit 2
fi

# Block GitHub CLI auth tokens
if printf '%s' "$FILE" | grep -qiE '\.config/gh/hosts\.yml'; then
    echo "BLOCKED: Reading GitHub CLI auth tokens is forbidden." >&2
    exit 2
fi

# Block HashiCorp Vault token
if printf '%s' "$FILE" | grep -qiE '\.vault[-_]token'; then
    echo "BLOCKED: Reading Vault token is forbidden." >&2
    exit 2
fi

# Block GitHub hub CLI config
if printf '%s' "$FILE" | grep -qiE '\.config/hub'; then
    echo "BLOCKED: Reading hub CLI config is forbidden (may contain OAuth token)." >&2
    exit 2
fi

# Block Java/Android keystores and signing configs
if printf '%s' "$FILE" | grep -qiE '(keystore\.jks|\.keystore|\.p12$|release-signing\.properties|gradle\.properties)'; then
    echo "BLOCKED: Reading keystore/signing config is forbidden." >&2
    exit 2
fi

# Block React Native sensitive configs
if printf '%s' "$FILE" | grep -qiE '(google-services\.json|GoogleService-Info\.plist|\.xcconfig)'; then
    echo "BLOCKED: Reading mobile platform secrets is forbidden." >&2
    exit 2
fi

# Block private key files
if printf '%s' "$FILE" | grep -qiE '\.(pem|key|pfx)$'; then
    echo "BLOCKED: Reading private key files is forbidden." >&2
    exit 2
fi

# Block Sentry/Bugsnag config files (contain DSN tokens)
if printf '%s' "$FILE" | grep -qiE 'sentry\.properties'; then
    echo "BLOCKED: Reading Sentry properties is forbidden (contains auth token)." >&2
    exit 2
fi

exit 0