# Hook Events — thin catalog

The four events this vault wires, the stdin fields each carries, and the decision form that fits. This is a quick-reference, **not** a reproduction of the official docs — for the full event list, matcher rules, and the complete JSON schema, see the Claude Code hooks documentation (`docs.claude.com` → Claude Code → Hooks).

## Events in use

| Event | Fires | Has matcher? | Key stdin fields | Can block? | Typical form |
| --- | --- | --- | --- | --- | --- |
| `PreToolUse` | before a tool runs | yes (tool-name regex) | `tool_name`, `tool_input.{file_path,command,…}` | yes | A (exit-code) or B (JSON-stdout) |
| `PostToolUse` | after a tool ran | yes (tool-name regex) | `tool_name`, `tool_input`, `tool_response` | no | A (exit 0; stderr advisory) |
| `UserPromptSubmit` | on prompt submit | no | `prompt` (NO `tool_input`) | yes (can stop the prompt) | A |
| `Stop` | at turn end | no | session/turn fields | no | A (exit 0; stderr advisory) |

## Field caution

The path field depends on the tool, not just the event: `Read`/`Edit`/`Write` carry `tool_input.file_path`; `Bash` carries `tool_input.command`; `UserPromptSubmit` carries `prompt` and **no** `tool_input` at all. Do not copy `file_path` blindly into a `UserPromptSubmit` hook — read the field the event actually provides.

## Decision forms (recap of SKILL.md Block 1)

- **Form A — exit-code:** `exit 2` + stderr → block; `exit 0` → allow; `exit 0` + stderr → warn (advisory). Never `exit 1` as a warn.
- **Form B — JSON-stdout:** print `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}` to stdout, then `exit 0`. Use only when a `PreToolUse` deny needs a model-visible structured reason.

## Common matchers (PreToolUse / PostToolUse)

`"Bash"`, `"Read"`, `"Edit|Write|MultiEdit"`, `".*"` (all tools). `UserPromptSubmit` and `Stop` registrations omit the matcher key entirely.
