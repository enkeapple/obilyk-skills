# Lessons Learned

Append-only. New entries go at the top of `## Entries`. When a `Cause-tag` recurs 3×, promote it to a rule under `.claude/rules/` and record it in `## Promoted clusters`. Mechanics: the `lessons-learned-protocol` skill.

## Entries

### 2026-06-19 — Naive fence-toggle corrupts markdown-in-markdown when auto-fixing

- **Cause-tag:** `markdown-fence-counting`
- **What happened:** A bulk fixer that added a language to "bare opening fences" treated every ` ``` ` as a toggle. In template files that wrap example fenced blocks in a four-backtick fence (` ````markdown ` … ` ```` `), the inner three-backtick fences are literal content; naive toggling desynced and appended `text` to *closing* fences.
- **Fix / rule:** Parse fences per CommonMark — a fence opened with N backticks closes only on a line of ≥N backticks with no info string; inner shorter fences are content. Same rule for skipping tables inside example blocks. Codified in [rules/common/markdown-style.md](rules/common/markdown-style.md) (Fenced-code bullet + Edge Cases).
- **Also:** Python `glob('**/*.md')` skips dot-directories (`.claude/`) — use `os.walk` for repo-wide markdown sweeps.

## Promoted clusters

(none yet — promote a cause-tag here once it reaches 3 entries)
