# Framework Conflict Audit — skills / rules / hooks

> Deep cross-artifact conflict audit (Map → Hunt → Verify → Synthesize, adversarially verified).
> Run: 38 agents · 46 artifacts mapped · 26 candidates → 14 confirmed / 12 refuted · deduped to **9 findings**.
> Date: 2026-06-19.

## Executive summary

**Confirmed conflicts after deduplication: 9** (the 14 confirmed candidates collapse — the four settings/quality-hook candidates are three underlying conflicts, and the two `handoff` candidates are one).

By severity: **2 HIGH · 4 MEDIUM · 3 LOW.**

Highest-impact themes:

1. **A React-Native / pnpm consumer stack is leaked into the vault's live harness.** `settings.json` pre-authorizes ten `pnpm run …` RN scripts, wires two PostToolUse hooks that run `npx eslint`/`npx jest` on every `.ts/.js` edit, and enables RN plugins — all in a repo the doctrine says has no `package.json`, no `src/`, no build/test pipeline. This is the single root cause behind four input candidates.
2. **The routed `handoff` skill bakes that same stack into shipped skill content** (`pnpm typescript`/`pnpm lint`, `src/shared/**` paths) and cites two skills that do not exist (`scaffold-slice`/`scaffold-api`) plus an enforcement barrier (`skill-gate.sh`) that is empty and cannot fire. This corrupts the actual product, not just config.
3. **Load-bearing doctrine is restated instead of cross-linked.** The two-layer-review ("feed the cold reviewer the source; disjoint remits or wasted load") principle, promoted to `scoping-skill-value.md`, is copied verbatim into three skills with zero backlink — a four-copy maintenance hazard in a vault whose own rule is "cross-link, don't restate."
4. **Stale structural counts and references in the domain charter.** `framework.md` hard-codes "12 skills" (really 18 routed), and links the lessons backlog with a dead relative path (`./lessons-learned.md` from `rules/domains/`).
5. **Dormant hooks and self-contradicting checklists carry leftover RN/superpowers strings** that misdescribe what can fire (skill-gate deny-reasons, detect-bypass header, the routing-sync "gap" annotation).

---

## Findings

### 1. [HIGH] `handoff/SKILL.md` leaks a pnpm/`src/shared` stack, cites non-existent `scaffold-*` skills, and asserts an enforcement barrier that cannot fire

**Locations:** `skills/process/handoff/SKILL.md:34,36,38,48` · `.claude/skills-routing.json` (`ruleGates: {}`) · `hooks/routing/skill-gate.sh:84,131` · contradicts `.claude/CLAUDE.md` Non-negotiable #2 and #7, `framework.md:40`, `glossary.md`.

**Why it is a conflict:** `handoff` is a routed, invocable skill (no `disable-model-invocation`), so it is held to the full agnostic bar — yet it hard-codes a TypeScript/RN consumer stack as fact, names two skills (`scaffold-slice`, `scaffold-api`) that exist nowhere on disk (`find skills -name SKILL.md` → none), and tells the resuming session those gated edits will be denied by `skill-gate.sh` — but `ruleGates` is `{}` and no skill declares `editGlobs`, so the gate loops iterate nothing and never deny. This trips Non-negotiable #2 (agnostic), #7 (skill names are structural claims), and the glossary's anti-leak doctrine simultaneously.

```text
:34  snapshot ground truth (not memory): `git status --short`, and `pnpm typescript` / `pnpm lint`
:36  Progress ledger keyed to the CODE layer order: Types/API/Slice/Hook/Screen/Nav/i18n
:38  name the routed skills ... (e.g. `scaffold-slice` before `src/shared/stores/**`,
     `scaffold-api` before `src/shared/api/**`), or `skill-gate.sh` will deny them.
:48  "I'll just finish the slice first..." — The gated edit forces a `scaffold-slice` invocation
```

**Fix:** `handoff/SKILL.md` is the artifact to change; the doctrine is correct. (1) Line 34: replace `pnpm typescript` / `pnpm lint` with "the consumer repo's typecheck/lint command (illustrative — e.g. `pnpm typescript` in a JS repo)". (2) Line 36: mark the `Types/API/Slice/…` ledger as the consumer's own layer order (illustrative). (3) Lines 38 + 48: drop `scaffold-slice`/`scaffold-api`/`src/shared/**` and the "or `skill-gate.sh` will deny them" assertion; reword to "name any routed skills/gates the consumer repo requires before its gated edits." Then RED/GREEN a cold resume scenario in a non-pnpm repo.

---

### 2. [HIGH] `settings.json` PostToolUse hooks run an `npx eslint`/`npx jest` pipeline the doctrine says cannot exist

*(Merges input candidates "Live PostToolUse quality hooks…", "Vault harness wires dead JS/TS eslint+jest hooks…" — same two files, same wiring.)*

**Locations:** `hooks/quality/lint-fix.sh:6-8` · `hooks/quality/test-quick.sh:6-8` · `.claude/settings.json:85-98` · contradicts `CLAUDE.md` ("No build / dev / test pipeline"), `glossary.md` ("no `package.json` / build / dev / unit-test pipeline"), `framework.md:40`.

**Why it is a conflict:** Both hooks are symlinked and wired live under PostToolUse matcher `Edit|MultiEdit|Write` (`settings.json:87-96`), firing on every edit and running a JS/TS toolchain. The vault doctrine repeatedly and explicitly forbids exactly this ("stack-specific verification … as if it were the vault's" is the named project-leak defect). The extension guards (`*.ts/.tsx/.js/.jsx`) make them inert on the vault's `.md`/`.sh` files, so there is no functional break — but their presence is a live doctrinal contradiction, not an illustrative example.

```bash
# test-quick.sh:8
npx jest --findRelatedTests "$FILE_PATH" --passWithNoTests 2>/dev/null || true
# lint-fix.sh:8
npx eslint --fix "$FILE_PATH" 2>/dev/null || true
```

**Fix:** The doctrine is canonical; the hooks are the drift. Remove the `lint-fix.sh`/`test-quick.sh` entries from `settings.json:85-98` and delete the two `hooks/quality/*.sh` files plus their `.claude/hooks/` symlinks. If a per-edit reflex is wanted, replace with a hook that runs the vault's real validators (frontmatter ≤1024, name regex, link resolution, fence balance) on changed `SKILL.md`/rule files.

---

### 3. [MEDIUM] Two-layer-review doctrine restated verbatim in three skills with no cross-link to its promoted owner

**Locations:** owner `.claude/rules/common/scoping-skill-value.md` (Two-layer review variant) · `skills/apply-chain/writing-specs/SKILL.md` · `skills/apply-chain/writing-plans/SKILL.md` · `skills/authoring/writing-rules/SKILL.md`.

**Why it is a conflict:** `scoping-skill-value.md` is the promoted canonical home of this doctrine (lessons-learned `skill-value-vs-noop`). The three skills each restate the load-bearing justification — "keep their remits disjoint, or the cold pass is wasted load" / "feed the cold reviewer the source" — almost word-for-word, and `grep -rln "wasted load"` returns exactly those three skills with **none** cross-linking the owner (`grep -rln scoping-skill-value` over `skills/` returns nothing). The vault's own anti-duplication rule is "cross-link, don't restate"; a doctrine change now touches four files.

> `scoping-skill-value.md`: "Feed the cold reviewer the source, not just the artifact … Split the checklists by reachability."
> `writing-specs:76`: "The two layers catch **different** classes of defect … Keep their remits disjoint, or the cold pass is wasted load."
> `writing-plans:86` / `writing-rules:75`: same "disjoint or the cold pass is wasted load" phrasing.

**Fix:** Keep each skill's artifact-specific recipe (which source to hand the reviewer: request/design for the spec, spec for the plan, rules-dir for the rule) but strip the generic justification and replace it with one cross-link to the owner, e.g. `[scoping-skill-value](../../../.claude/rules/common/scoping-skill-value.md)` — "see its Two-layer review variant." Verify `grep -rln "wasted load" skills/` returns nothing afterward and the relative link resolves (`skills/<cat>/<name>/` → `../../../.claude/rules/common/`).

---

### 4. [MEDIUM] `settings.json` allow-list pre-authorizes a React-Native pnpm script set absent from this `package.json`-less vault

*(Merges input candidates "settings.json carries a React-Native pnpm/jest harness…" and "settings.json allow-list pre-authorizes dead RN pnpm scripts…" — same allow-list block.)*

**Locations:** `.claude/settings.json:7-18` (and RN plugins `:150-151`) · contradicts `CLAUDE.md` ("No application code, no `package.json`"), `glossary.md`, `framework.md:3,40`.

**Why it is a conflict:** The allow-list whitelists ten RN-shaped commands (`android`, `watchman:clean`, `ports:kill`, `config:clean`, `postinstall`, `version:name`, …). There is no `package.json` in the repo, so these scripts cannot resolve — they are a foreign consumer stack baked into the vault's own harness config, the exact "any pnpm reference is a consumer-repo leak" the doctrine names. (Note: the input candidate's claim that a self-flagging "project-specific" note exists in the mapping JSON is **false** — no such note is in `skills-routing.json` or `CLAUDE.md`; do not cite it.) Dead entries, so impact is low-functional but doctrinally inconsistent.

```json
"Bash(pnpm run android:*)", "Bash(pnpm run watchman:clean:*)",
"Bash(pnpm run ports:kill:*)", "Bash(pnpm run version:name:*)"
```

**Fix:** Prune the ten `Bash(pnpm run …:*)` allow-entries from `settings.json:7-18` (the doctrine says the only routine shell use is read-only git + validators). Reconsider the `react-native-best-practices`/`upgrading-react-native` plugins (`:150-151`) unless intentionally enabled for APPLY-mode consumer work. If any of this MUST stay for dogfooding against an RN consumer repo, add a one-line carve-out in `.claude/CLAUDE.md` naming `settings.json` as the single sanctioned place for consumer harness config, and have the "pnpm is a leak" doctrine cross-link it.

---

### 5. [MEDIUM] `framework.md:44` links the lessons backlog with a dead relative path

**Locations:** `.claude/rules/domains/framework.md:44` · target `.claude/lessons-learned.md` · correct sibling `glossary.md:33`.

**Why it is a conflict:** From `rules/domains/`, `[lessons-learned.md](./lessons-learned.md)` resolves to `rules/domains/lessons-learned.md`, which does not exist (`ls` → No such file); the real file is two levels up at `.claude/lessons-learned.md` (22831 bytes). Sibling references at the same depth use the correct `../../` (`glossary.md:33`, `scoping-skill-value.md:17`), proving a copy-paste depth error. The dead link sits in the Question Discipline search order — the one place an agent is told to consult the backlog before asking — so it fails silently exactly where it is followed.

> `framework.md:44`: "…→ `.claude/rules/` → [lessons-learned.md](./lessons-learned.md) → `git log` …"

**Fix:** In `framework.md:44`, change `(./lessons-learned.md)` to `(../../lessons-learned.md)` to match the sibling depth. (Line 3 of the same file already uses the correct `../../` form, so only line 44 is wrong.)

---

### 6. [MEDIUM] `detect-bypass.sh` header comment understates the matcher set its body and `settings.json` rely on

**Locations:** `hooks/routing/detect-bypass.sh:2` · `.claude/settings.json:108-114`.

**Why it is a conflict:** The header documents the hook as "matcher: Read|Skill", but `settings.json:109` registers it with `Read|Skill|Edit|Write|MultiEdit`, and the body's check 1b (the direct-edit-to-`lessons-learned.md` detector, lines 81-91) only fires on Edit/Write/MultiEdit events. A reader trusting the header would conclude that detector is dead code. Documentation-only divergence (the wiring is correct), hence medium-leaning-low.

> `detect-bypass.sh:2`: "# PostToolUse hook (matcher: Read|Skill): detect skill bypass."
> `settings.json:109`: `"matcher": "Read|Skill|Edit|Write|MultiEdit"`

**Fix:** The `settings.json` matcher is authoritative. Update `detect-bypass.sh:2` to `# PostToolUse hook (matcher: Read|Skill|Edit|Write|MultiEdit): detect skill bypass.` and optionally extend the lines 3-5 summary to mention check (1b). No `settings.json` change.

---

### 7. [LOW] `framework.md:25` hard-codes "the registry has 12 skills"; routing has 18

**Locations:** `.claude/rules/domains/framework.md:25` · `.claude/skills-routing.json`.

**Why it is a conflict:** Suspicion-Protocol step 5 pins a count that is stale: `jq '.skills | keys | length'` → 18 routed entries (20 `SKILL.md` on disk; 2 are `disable-model-invocation` and unrouted). "12" undercounts by 6. It is parenthetical color inside a sound instruction, so behavior is unaffected, but it misleads a human reading it as a duplicate-scan target.

> `framework.md:25`: "…grep for an existing one that already covers it (the registry has 12 skills); extend rather than fork."

**Fix:** Drop the brittle number rather than re-pinning it (it will restale on the next skill add). Replace "(the registry has 12 skills)" with "grep `.claude/skills-routing.json` and `skills/**` for an existing one."

---

### 8. [LOW] `skill-routing-sync.md:62` flags a `disable-model-invocation` skill as a missing-key "gap" its own clause excludes

**Locations:** `.claude/rules/common/skill-routing-sync.md:62` · `skills/design/improve-codebase-architecture/SKILL.md:4` · `.claude/skills-routing.json`.

**Why it is a conflict:** The same checklist sentence scopes the every-skill-has-a-key check to "(excluding `disable-model-invocation` reference skills)" and then labels `improve-codebase-architecture` a "Known carried-forward gap: has no key yet." But that skill sets `disable-model-invocation: true`, so by the clause's own scope (and the file's Edge Cases at line 56: "do NOT add a `triggers` entry") it must NOT have a key and is not a gap. The annotation mislabels correct disk state as drift and could push a maintainer to add a forbidden entry.

> `skill-routing-sync.md:62`: "…(excluding `disable-model-invocation` reference skills) … Known carried-forward gap: `improve-codebase-architecture` has no key yet."
> `improve-codebase-architecture/SKILL.md:4`: `disable-model-invocation: true`

**Fix:** Delete the "Known carried-forward gap…" clause from the line-62 item. If a reminder is wanted, move it into Edge Cases as a positive confirmation: "`improve-codebase-architecture` is `disable-model-invocation: true`, so its absence from routing is correct, not a gap."

---

### 9. [LOW] `skill-gate.sh` comments and dormant deny-reason strings carry RN/superpowers consumer leakage

**Locations:** `hooks/routing/skill-gate.sh:3,17,55-59,88,141` · contradicts `glossary.md` ("no `src/`").

**Why it is a conflict:** The hook's comments and never-emitted deny-reason strings name `src/shared/api`/`src/shared/stores` as gated domains, point persisted facts at `docs/superpowers/specs/` (a store the vault never defines), and assert ownership of "routes/APIs/i18n" — all RN consumer concepts the vault has no `src/` for. Because `ruleGates` is `{}` and no skill declares `editGlobs`, Pass-1 and Pass-2 never fire, so these strings are inert; only the Pass-0 memory block (with its `docs/superpowers/specs/` token) can emit. `.claude/CLAUDE.md:105` already concedes the gates are dormant, so this is text-only cleanup, not a live behavioral break.

> `skill-gate.sh:3`: "# Blocks an edit/write inside a skill-owned domain (e.g. src/shared/api, src/shared/stores)"
> `skill-gate.sh:141`: "…which of the three independent document-ish domains owns which routes/APIs/i18n…"

**Fix:** Sanitize to stack-agnostic text (no behavior change): line 3 → "(a skill-owned editGlob configured in skills-routing.json)"; line 17 → drop "(api, slice)"; lines 55/59 → drop `docs/superpowers/specs/`, keep only the vault's real stores (`.claude/lessons-learned.md`, `.claude/rules/<area>/<topic>.md`); line 88 → drop "(schemes/adapters/tags/selectors)"; line 141 → "which rule owns this domain."

---

## Cross-cutting themes

**Theme A — Carried-forward React-Native / pnpm consumer stack leaked into vault harness (Findings 1, 2, 4, 9; touches 6).** The single largest root cause. The vault was scaffolded from an RN project and the foreign stack survives in four places: the `settings.json` allow-list and RN plugins (#4), the live `eslint`/`jest` PostToolUse hooks (#2), the inert RN strings in `skill-gate.sh` (#9), and — most seriously — inside a *shipped* skill body, `handoff` (#1). The doctrine (`CLAUDE.md`, `glossary.md`, `framework.md`) is internally consistent and correct; the harness and one skill are the drift. Systemic issue: **the vault dogfoods its own harness but never audited that harness against the no-pipeline doctrine it preaches.** The `dogfood-generator-sync.md` rule governs instance↔generator↔auditor propagation but explicitly exempts hooks/`settings.json` as "vault-only instances," so nothing forces these harness files into conformance.

**Theme B — Restatement instead of cross-link among owned doctrines (Finding 3).** The vault's stated discipline is "name one canonical owner, cross-link, don't restate." The two-layer-review principle violates it: promoted to `scoping-skill-value.md`, then copied verbatim into three apply-chain skills. Systemic issue: **promotion of a lesson to a rule did not back-fill cross-links into the skills that already embodied it**, leaving four divergent copies.

**Theme C — Stale structural metadata in the domain charter and hook docs (Findings 5, 6, 7, 8).** Hard-coded counts ("12 skills"), depth-wrong relative links (`./lessons-learned.md`), out-of-date header comments (`detect-bypass.sh`), and self-contradicting checklist annotations (`skill-routing-sync.md`). Systemic issue: **descriptive metadata about the repo's own shape drifts because it is hand-maintained and not validated** — the same class the glossary warns about ("a glossary cell that greps to nothing is a defect"), but uncaught here because these live outside the glossary's own audit surface.

---

## Not conflicts (checked & cleared)

- **`writing-plans` execution-mode fork vs `sdd-lifecycle` / `pre-implementation-protocol`:** Refuted as a three-way contradiction. `pre-implementation-protocol:36` *records* the chosen flow, it does not present a picker; its own gate is archetype C-readiness. `sdd-lifecycle` and `interactive-gates.md` cross-link cleanly with a single named owner. The only real residue is a **low** missing-guard in `writing-plans` (it offers the fork unconditionally rather than only when standalone) — a cross-link gap, not a behavioral contradiction.
- **`writing-specs` / `grilling` standalone approval gates use prose:** Half refuted. `grilling` is explicitly carved out at `interactive-gates.md:22` as the conversational interview — its prose is intended, not drift. Under `sdd-lifecycle` the gate *is* archetype A. The residue is a **low** standalone-only missing cross-link in `writing-specs:99-103` — a propagation gap, not a mutual contradiction.
- **`skill-gate.sh` "empty ruleGates" as a contradiction with `handoff`'s gate claim:** The *empty gate* itself is not a defect — `.claude/CLAUDE.md:105` openly documents it. The defect is `handoff` asserting the gate will fire (folded into Finding 1), not the gate being empty.
