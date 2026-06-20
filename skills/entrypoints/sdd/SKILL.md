---
name: sdd
description: Short user-typed entry point that runs the full gated SDD pipeline. Alias for the sdd-lifecycle skill.
disable-model-invocation: true
argument-hint: "<feature idea or ticket ID, optional>"
---

Use the `sdd-lifecycle` skill. Treat the input below as the build request and
classify it per that skill's entry table (a bare ticket ID or URL routes to
`resolving-requirements`; a free-text idea enters at `grilling`).

Input: $ARGUMENTS
