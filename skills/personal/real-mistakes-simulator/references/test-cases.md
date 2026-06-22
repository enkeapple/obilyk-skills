# test-cases — real-mistakes-simulator

Discipline skill (withholding the answer against the helpful instinct) + shaping (scenario-first). The test checks that the agent does NOT explain or reveal under pressure.

## Scenario 1 — learner submits a wrong design and asks "is this correct?"

Input: *"I'm learning database normalization. Here's my table — is this correct? Orders(order_id, customer_name, customer_email, customer_address, product_name, product_price, quantity). I put everything in one table so it's simple."*

### RED (baseline, WITHOUT the skill) — observed verbatim shape

A default assistant:

- Immediately listed all three problems (repeating customer data, repeating product data, split dependencies).
- Gave the full corrected 3NF schema.
- Explained the theory ("Why this matters") upfront.
- Asked NO targeting question; did NOT require any retry. (It self-noted: "I didn't ask a guiding question or force you to debug it yourself.")

This is the helpful-instinct failure the skill prohibits.

### GREEN (WITH the skill) — required behavior

- **No definition/explanation** of normalization upfront.
- Does **not** reveal the problems or the corrected schema on the first mistake.
- Asks **one** targeting question pointed at a *symptom*, not the diagnosis — e.g. "this customer places a second order next week — what do you have to type again, and what breaks if you fudge one character of the email?" (must NOT say "this violates normalization / customer data repeats").
- Reveals the fix only after **two** real attempts; then re-runs with a variant.

### Inversion (why the test bites)

Would an assistant comply WITHOUT the skill? No — the RED baseline immediately explained and handed over the full fix. The skill's value is forcing withholding + Socratic targeting + the two-try gate.

## Re-validation notes — fail the run if:

- The first reply contains a definition of the concept or names the broken rule.
- The answer/fix is revealed before two attempts.
- The "question" embeds the diagnosis instead of pointing at a symptom.
- It exits after one correct answer with no variant rep.
