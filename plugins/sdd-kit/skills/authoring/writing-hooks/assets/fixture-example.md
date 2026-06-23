# Fixture Example — the RED oracle, worked

A hook's "test" is a crafted stdin piped to the script, asserting the decision. Below is a complete RED→GREEN fixture set for a Form A (exit-code) `PreToolUse` guard that blocks reading `.env`. Each fixture is independent; **keep the RED-0 and the fail-open-0 distinct**.

## Setup

```bash
cp assets/hook-template.sh /tmp/hook.sh && chmod +x /tmp/hook.sh
# For this smoke run, set <pattern> to: \.env(\.|$)   and <reason> to: reading .env is forbidden
```

## The four fixtures

```bash
# 1. DENY case — a forbidden path
echo '{"tool_input":{"file_path":"/proj/.env"}}' | /tmp/hook.sh; echo $?
#    RED  (logic not written): 0      ← the guard does nothing yet
#    GREEN (logic written):    2      ← blocks, message on stderr

# 2. ALLOW case — an unrelated path must never be blocked
echo '{"tool_input":{"file_path":"/proj/README.md"}}' | /tmp/hook.sh; echo $?
#    always: 0

# 3. WARN case (only if the hook warns instead of blocks) — exit 0 AND stderr message
out=$(echo '{"tool_input":{"file_path":"/proj/.env"}}' | /tmp/hook.sh 2>err); echo $?; grep -q 'forbidden' err && echo "warned"
#    0 + "warned"

# 4. FAIL-OPEN case — garbage / empty stdin must allow, NOT block
printf 'not json'              | /tmp/hook.sh; echo $?    # MUST be 0
printf ''                      | /tmp/hook.sh; echo $?    # MUST be 0
echo '{"tool_input":{}}'       | /tmp/hook.sh; echo $?    # MUST be 0  (empty target field)
```

## Why fixture 1's RED-0 is not fixture 4's fail-open-0

Both print `0`, but they mean opposite things:

- **Fixture 1 RED-0** = "the block logic isn't written yet" → it must become `2` at GREEN.
- **Fixture 4 fail-open-0** = "on garbage input the guard correctly stays out of the way" → it must STAY `0` forever.

If you collapse them into one fixture you cannot tell a not-yet-implemented guard from a correctly-failing-open one. Assert them separately.

## Form B (JSON-stdout) oracle

```bash
echo '{"tool_name":"Read","tool_input":{"file_path":"/proj/.env"}}' | /tmp/hook.sh \
  | jq -r '.hookSpecificOutput.permissionDecision'
#    RED:   ""  or  null
#    GREEN: "deny"
```

## Wiring check (Block 4)

```bash
test -x /tmp/hook.sh && echo "executable"
# in a real install: readlink the discovery symlink resolves, and settings.json registers
# the right event + matcher:
jq '.hooks.PreToolUse' .claude/settings.json    # entry present, matcher matches the intended tool
```
