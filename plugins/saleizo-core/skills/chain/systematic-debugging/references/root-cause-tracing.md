# Root-Cause Tracing

Trace a bad value **backward** through the call chain to where it first became wrong, then fix it there. The line that throws is where the problem *surfaced*, almost never where it *started*.

## Method

1. **Observe the symptom** — the exact error and the value that is wrong (e.g. an "invalid input" thrown on the string `"undefined/users"`).
2. **Find the immediate cause** — the line that produced the bad value or threw on it.
3. **Ask "what called this with that value?"** — step one frame up the call chain.
4. **Keep tracing up** — repeat until the value is no longer wrong; the last frame where it was *still correct* brackets the origin.
5. **Find the original trigger** — usually an entry point, configuration, initialization, or test setup that supplied (or failed to supply) the value.

Fix at that origin. If the same bad value could arrive through more than one path, also see [defense-in-depth.md](./defense-in-depth.md).

## Instrument when the chain is opaque

When you cannot read the chain statically, make it print where the value comes from. Capture a stack at the suspect operation and log the inputs:

```text
# illustrative — use your language's stack-capture + an output channel the test actually shows
log_error("DEBUG <operation>:", { value, caller_stack: capture_stack() })
```

- Use an output channel the harness **actually surfaces** during the failing run — in many test runners a buffered logger is swallowed while the standard error stream is shown. If you see nothing, you are writing to a silenced channel, not proving absence.
- Filter the run's output to your marker (e.g. grep the test output for `DEBUG <operation>`) so the trace is readable.
- Remove the instrumentation once the origin is found.

## The rule

**Never fix only where the error appears.** A guard at the symptom (a try/catch, a default, a null-check at the throw site) silences the evidence and ships the bug; the same bad value will resurface through the next path that lacks the guard. Remove the cause at its source.
