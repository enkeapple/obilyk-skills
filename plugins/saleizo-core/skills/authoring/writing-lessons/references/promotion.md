# Promotion Path — lesson → rule

The procedure reached only when the promotion-debt scan flags a cause-tag at the threshold (count ≥ 3) with no `## Promoted clusters` ledger line. The high-frequency capture path lives in `SKILL.md`; this is the branch only some runs reach.

When the same cause-tag reaches the threshold, it is a pattern, not a one-off. Do not decide promotion by gut — dispatch an independent reviewer that judges whether it generalizes and at what level it belongs, using [../assets/promotion-reviewer-prompt.md](../assets/promotion-reviewer-prompt.md). It returns one of: Promote (with target rule file + actionable rule text), Keep in lessons (too situational / already covered), or Re-tag (not a real cluster).

If the reviewer says **Promote**, apply its output:

1. **Author the rule with the `writing-rules` skill**, feeding it the reviewer's drafted rule text and target path as the starting point. It owns the rule's shape — `paths` scoping, `## When`, the ✅/❌ example, the Review Checklist.

   > REQUIRED SUB-SKILL: Use `writing-rules` to write the promoted rule file at `.claude/rules/<...>.md`. Do not hand-author it here — this skill owns the *promotion decision and bookkeeping*; `writing-rules` owns the *rule's shape*.
2. **Delete the contributing entry bodies** from `## Entries` (git preserves them via `git log -S`). Deletion is allowed ONLY here, inside this confirmed-promotion change — never as a standalone log tidy.
3. Add a ledger line under `## Promoted clusters`: `- <cause-tag> → rules/<...>.md (YYYY-MM-DD)`. This is what the scan reads to know the cluster is resolved.
4. Commit the new/extended rule, the entry deletions, and the ledger line together (one commit).

The rule file is the durable artifact. The ledger only points to it — never leave the actual rule sitting inside the lessons log. If the reviewer says **Keep in lessons**, add a ledger line recording why, so the scan stops flagging it as debt.
