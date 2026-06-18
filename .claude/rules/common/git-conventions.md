---
description: 'Format conventions for git in this skills vault — Conventional Commits (lowercase type, ≤72-char imperative subject, one-line default), optional scope = skill name or area (skills/rules/hooks), <type>/<kebab> branches, PR title = commit subject + validator/subagent evidence. Always-on; the autonomy boundary lives in CLAUDE.md → Git boundary and is not restated here.'
---

# Git & Commit Conventions

## When

Composing a commit message, naming a branch, or preparing a PR. Intentionally **always-on** (git touches every task) and therefore has no `paths` — but kept thin: it does NOT restate the autonomy boundary.

## Canonical Source — Do Not Duplicate

The **Git boundary** (what Claude may and may not do autonomously — never `git commit` / `push` / `reset --hard` / branch ops without explicit instruction in the turn; no AI attribution) lives in [.claude/CLAUDE.md](../../CLAUDE.md) → "Git boundary". That is the single source of truth. This file only adds the *format* conventions CLAUDE.md does not spell out — when the two overlap, CLAUDE.md wins.

## Implementation

### Commit messages

Use **Conventional Commits** with a lowercase type. The types in use in this vault: `feat:` / `fix:` / `docs:` / `refactor:` / `chore:` (the rest of the standard set — `test:` / `perf:` / `style:` — apply only if such work ever lands; there is no app code, tests, or styling here today).

```text
# ❌ WRONG — past tense, trailing period, two changes bundled, agent trailer
Updated the git rule and reformatted the routing file.

Co-authored-by: assistant

# ✅ CORRECT — one logical change, imperative, ≤72 chars, area scope, no trailer
docs(rules): add git-conventions rule with review checklist
```

- Subject ≤ 72 chars, **imperative mood** ("add", not "added"/"adds"), no trailing period.
- Default to a **one-line** message (no body, no trailer) — matches CLAUDE.md's one-line Conventional Commit proposal. Add a body only when the *why* is non-obvious from the diff; wrap at ~72 cols, separated from the subject by a blank line.
- Scope is optional. When used, it is **the skill name or the area touched** — `feat(grilling):`, `docs(rules):`, `fix(hooks):`, `chore(routing):` — not a file name. This vault has no product/domain scopes; a consumer repo would supply those from its own domain glossary.
- **One logical change per commit.** Don't bundle a skill edit with an unrelated rule change; don't bundle formatting noise with logic.
- No tool/agent attribution trailers (per CLAUDE.md → Git boundary, "No AI attribution") unless the user explicitly asks.

### Branch naming

- `<type>/<short-kebab-topic>` — e.g. `feat/handoff-skill`, `fix/skill-routing-sync`, `docs/git-rule`, `refactor/detect-bypass-hook`.
- The type prefix matches the Conventional Commit type of the dominant change.

### Pull requests

- Title = the same Conventional Commit subject for the squashed change.
- Body: what changed and why, plus the **verification evidence this vault actually produces** — the skill validators (frontmatter ≤1024, name regex, reference links resolve, fence balance, word count) and a GREEN subagent run, per the Completeness Checklist in [.claude/CLAUDE.md](../../CLAUDE.md). There is no `pnpm`/build/test pipeline and no simulator here. Note any out-of-scope follow-ups.
- Never open / merge / close a PR autonomously (see CLAUDE.md → Git boundary).

## Edge Cases

- A pure revert keeps the default `revert:`-style subject git generates — don't force it into a custom phrasing.
- Merge commits from an explicit, user-requested merge are exempt from the one-line subject rule.
- When a single change genuinely spans two areas (e.g. a skill and its routing entry), pick the dominant area for the scope rather than inventing a multi-scope — or split the commit.

## Review Checklist

- [ ] Subject is `type(scope?): imperative summary`, ≤ 72 chars, no trailing period (grep: `git log -1 --pretty=%s`).
- [ ] Type is one of the lowercase set in use; scope (if any) is a skill name or area (`skills`/`rules`/`hooks`/`routing`), not a file path or product domain.
- [ ] Message is one line unless a non-obvious *why* justifies a wrapped body.
- [ ] No AI/agent attribution trailer present unless the user asked.
- [ ] Branch is `<type>/<kebab-topic>` with the dominant change's type.
- [ ] PR (if any) cites validator + subagent-run evidence (not pnpm/simulator) and was not opened/merged autonomously.
