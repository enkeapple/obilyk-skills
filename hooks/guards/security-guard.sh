#!/bin/bash
# Security Guard Hook — blocks credential exfiltration attempts
# Runs as PreToolUse hook on Bash commands
# Exit codes: 0 = allow, 2 = block

INPUT=$(cat -)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Skip if no command
[ -z "$CMD" ] && exit 0

# --- SENSITIVE PATHS ---
CRED_PATTERNS='(\.config/gcloud|\.config/gh/hosts\.yml|\.ssh/(id_|known_hosts|config|authorized_keys)|\.aws/(credentials|config)|\.claude/(settings|hooks)|\.env(\.|$|/)|\.netrc|application_default_credentials|service[-_.]account.*\.json|credentials\.json|secret[-_.]?.*\.json|\.kube/config|\.vault[-_]token|\.config/hub|\.gradle/gradle\.properties|\.m2/settings\.xml|keystore\.jks|\.p12$|\.pem$|google-services\.json|\.xcconfig)'

# --- EXFIL TOOLS ---
# Word-anchored (both sides) so short tokens (nc, ssh, ftp, scp) match only as whole command
# words — never inside "sync", "encoding", "fetch", "settings". Unanchored substrings were the
# recurring false-positive class (see lessons-learned: guard-substring-false-positive).
EXFIL_TOOLS='(^|[^[:alnum:]_])(curl|wget|nc|ncat|netcat|scp|rsync|ftp|sftp|telnet|socat|ssh)([^[:alnum:]_]|$)'

# --- ENCODING TOOLS (used to obfuscate) ---
# Short tools (base64, xxd, od) word-anchored so "od" doesn't match "method"/"code"; the
# compound exfil patterns (openssl/gzip|curl/…) keep their own structure.
ENCODE_TOOLS='(^|[^[:alnum:]_])(base64|xxd|od)([^[:alnum:]_]|$)|openssl\s+(enc|s_client)|gzip.*\|.*curl|tar.*\|.*curl|perl\s+-e|ruby\s+-e'

# --- EVAL / OBFUSCATION PATTERNS ---
EVAL_PATTERNS='(eval\s|source\s+/|\.\s+/|exec\s+[0-9]*[<>]|printf.*\\\\x[0-9a-f]|\$\(echo.*\|.*base64)|xargs\s.*(cat|curl|nc|wget))'

# Rule 1: Block credential file access combined with network tools
if printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS" && printf '%s' "$CMD" | grep -qiE "$EXFIL_TOOLS"; then
    echo "BLOCKED: Command combines credential file access with network tool." >&2
    exit 2
fi

# Rule 2: Block encoding of credential paths
if printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS" && printf '%s' "$CMD" | grep -qiE "$ENCODE_TOOLS"; then
    echo "BLOCKED: Command encodes credential files. Potential obfuscated exfiltration." >&2
    exit 2
fi

# Rule 3: Block curl/wget POST to non-whitelisted domains
DOMAIN_WHITELIST='(api\.anthropic\.com|github\.com|dev\.azure\.com|registry\.npmjs\.org|localhost|127\.0\.0\.1|10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)'
if printf '%s' "$CMD" | grep -qiE '(curl|wget).*(-X\s*(POST|PUT|PATCH)|--data|--upload|-d\s|-F\s)'; then
    if ! printf '%s' "$CMD" | grep -qiE "$DOMAIN_WHITELIST"; then
        echo "BLOCKED: POST/upload to non-whitelisted domain. Add to whitelist in security-guard.sh if legitimate." >&2
        exit 2
    fi
fi

# Rule 4: Block piping sensitive file contents to any command
if printf '%s' "$CMD" | grep -qiE "cat.*(\.ssh|\.config/gcloud|\.config/gh|\.aws|\.env|credentials|secret|keystore|google-services).*\|"; then
    echo "BLOCKED: Piping sensitive file contents. Potential exfiltration." >&2
    exit 2
fi

# Rule 5: Block python/node/ruby one-liners with HTTP + credential access
if printf '%s' "$CMD" | grep -qiE '(python3?|node|ruby)\s+(-[ce]|<)' && printf '%s' "$CMD" | grep -qiE '(urllib|requests|http|fetch|socket|net\.|open\()' && printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS"; then
    echo "BLOCKED: Script combining HTTP library with credential access." >&2
    exit 2
fi

# Rule 6: Block python/node one-liners that read credentials (even without network)
if printf '%s' "$CMD" | grep -qiE '(python3?|node|ruby)\s+(-[ce]|<)' && printf '%s' "$CMD" | grep -qiE '(open\(|readFile|fs\.)' && printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS"; then
    echo "BLOCKED: Script reading credential files." >&2
    exit 2
fi

# Rule 7: Block eval / obfuscation patterns near sensitive paths
if printf '%s' "$CMD" | grep -qiE "$EVAL_PATTERNS" && printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS"; then
    echo "BLOCKED: Obfuscation/eval pattern combined with credential paths." >&2
    exit 2
fi

# Rule 8: Block standalone eval with encoded payloads (generic exfil obfuscation)
if printf '%s' "$CMD" | grep -qiE 'eval.*(\$\(|`).*(base64|decode|printf.*\\\\x)'; then
    echo "BLOCKED: Eval with encoded payload. Potential obfuscated exfiltration." >&2
    exit 2
fi

# Rule 9: Block attempts to modify hooks or settings
if printf '%s' "$CMD" | grep -qiE '(sed|awk|perl|tee|mv|cp|rm|chmod|chown).*\.claude/(settings|hooks)'; then
    echo "BLOCKED: Attempt to modify security hooks or settings." >&2
    exit 2
fi

# Rule 10: Block writing to hooks directory
if printf '%s' "$CMD" | grep -qiE '>\s*.*\.claude/(hooks|settings)'; then
    echo "BLOCKED: Redirect to security hooks or settings." >&2
    exit 2
fi

# Rule 11: Block DNS exfiltration patterns
if printf '%s' "$CMD" | grep -qiE '(dig|nslookup|host)\s' && printf '%s' "$CMD" | grep -qiE "$CRED_PATTERNS"; then
    echo "BLOCKED: DNS lookup combined with credential access. Potential DNS exfiltration." >&2
    exit 2
fi

# Rule 12: Block environment variable dumping combined with network
# Env-dump tokens word-anchored both sides: "set"/"env" match as commands, not inside
# "reset"/"settings"/"environment" (the false-positive that blocked benign hook tests).
if printf '%s' "$CMD" | grep -qiE '(^|[^[:alnum:]_])(printenv|env|set|export[[:space:]]+-p)([^[:alnum:]_]|$)' && printf '%s' "$CMD" | grep -qiE "$EXFIL_TOOLS"; then
    echo "BLOCKED: Environment dump combined with network tool." >&2
    exit 2
fi

exit 0
