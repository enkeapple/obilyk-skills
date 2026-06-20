# Frontmatter Reference

The YAML frontmatter block of a `SKILL.md`. Two fields do the load-bearing work (`name`,
`description`); the rest are optional levers. The `create`/`edit` branches OFFER the relevant
optional fields and the `validate` gate checks every present key against this set and its format.

## Authoritative field set

A frontmatter key not in this list is a likely typo — the validator flags it.

| Field | Type / values | What it does |
| --- | --- | --- |
| `name` | `^[a-z0-9-]+$`; MUST equal the dir name (and the flat-symlink name) | the skill's identity / invocation key |
| `description` | string | model-invoked: triggers + reach (every word costs context load). user-invoked: human-facing one-liner, no trigger list |
| `when_to_use` | string | optional elaboration of triggering conditions |
| `argument-hint` | string | hint shown for `$ARGUMENTS` |
| `arguments` | space-separated string or YAML list | declared argument names |
| `disable-model-invocation` | boolean | `true` ⇒ user-invoked only; strips the description from model reach; NO `skills-routing.json` entry |
| `user-invocable` | boolean | whether a human may invoke it by name |
| `allowed-tools` | space/comma string or YAML list | see below |
| `disallowed-tools` | space/comma string or YAML list | the inverse — tools to withhold |
| `model` | full model ID, alias (`opus`/`sonnet`/`haiku`), or `inherit` | see below |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` | reasoning-effort override |
| `context` | `fork` | run the skill in a forked context |
| `agent` | agent type (e.g. `Explore`, `Plan`, `general-purpose`) | run the skill as that agent |
| `hooks` | YAML object | skill-scoped hooks |
| `paths` | comma string or YAML list of globs | scope the skill to matching files |
| `shell` | `bash` or `powershell` | shell for the skill's commands |

## The two fields to offer during create/edit

### `allowed-tools` (optional)

```yaml
allowed-tools: Read, Grep, Glob          # comma form
allowed-tools: Read Grep Glob            # space form
allowed-tools:                           # YAML-list form
  - Read
  - Bash(git status *)
```

- **Semantics:** AUTO-GRANTS the listed tools without a permission prompt while the skill is active. It does **not** restrict the rest — every other tool remains callable under the normal permission settings. To *withhold* tools, use `disallowed-tools`.
- **Offer it when:** the skill runs a known, narrow tool set and you want to cut approval friction — or, paired with `disallowed-tools`, to keep a destructive tool out of an authoring skill.
- **Trade-off:** a broad `allowed-tools` widens what runs unprompted; keep it to the tools the skill actually uses.

### `model` (optional)

```yaml
model: opus            # alias
model: claude-opus-4-1-20250805   # full id
model: inherit         # keep the active session model
```

- **Semantics:** overrides the session model while the skill is active; resumes the session model on the next prompt. Not saved to settings.
- **Offer it when:** the skill's work has a clear model fit — a cheap mechanical pass (a smaller model) or a hard reasoning/judgment pass (a larger one).
- **Trade-off:** pinning a model couples the skill to a model lineage; prefer `inherit` (or omit) unless a tier genuinely fits. Validate the value is a real id/alias/`inherit`.

## Validation note

When present, `allowed-tools`/`disallowed-tools` must be a space/comma string or a YAML list of
tool names; `model` must be `inherit`, a known alias, or an id of the form `claude-*`. Absent is
legal — both are optional. The full check list lives in `validation-checklist.md`.
