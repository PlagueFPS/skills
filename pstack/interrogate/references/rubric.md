# Review Rubric

Review through whichever lenses are relevant. Not every lens applies to every change.

## Correctness

Does the code actually do what the intent says it should?

- Edge cases: empty collections, null/undefined, boundaries, unicode, zero values
- Error handling: are errors caught, propagated, or silently swallowed?
- Off-by-one, type coercion, integer overflow, string encoding
- State management: race conditions, stale closures, dangling references
- Do both the happy path and the sad path work?
- Idempotency: what happens if this operation runs twice, or if a previous run crashed halfway? If the answer is "it depends on what state was left behind," a reconciliation step is missing.
- Concurrency: if multiple actors can touch the same mutable state (files, branches, shared data), is access serialized structurally (locks, sequential phases, exclusive ownership), or by conventions that won't hold?

When you find a potential bug, trace the execution path. Don't just flag "this could be nil". Show the call chain that makes it nil.

## Root Causes vs. Symptoms

Is the code fixing the actual problem or papering over a symptom?

Answering this often requires looking beyond the changed files. Read the surrounding code (callers, callees, type definitions, sibling modules) and understand the architecture the change lives in. Follow the call chain, read the types, and understand why the code exists before judging whether the change addresses the right layer.

- Guard clauses that mask a deeper invariant violation
- Retry logic that hides a broken contract
- Type casts that silence a modeling error
- A workaround: why is it needed? What would a proper fix look like?
- A fix in module A that should really be a fix in module B's contract
- Instructions where structure would be better: if the fix is a comment saying "don't do X" or a convention someone has to remember, ask whether it could instead be a type constraint, a lint rule, or a runtime check that makes the wrong thing impossible

## Architecture & System Design

Does the code fit well into the system it's part of?

- Boundary discipline: is validation at system boundaries, or scattered through business logic? Validate data once where it enters the system, then trust it internally.
- Abstraction level: is the code mixing high-level orchestration with low-level detail?
- Coupling: does this change introduce dependencies that will make future changes harder?
- Data model fit: do the data structures match the actual access patterns?
- Bolted-on vs. integrated: if the new requirement had been known from the start, would the code look like this, or does the change feel patched onto the existing design?
- Legacy dual-paths: does the change introduce a new API while keeping the old one alive? If there are no external consumers, migrate callers and delete the old path in the same wave. Don't leave compatibility layers that will become permanent.

Don't penalize simple code for lacking abstraction. Premature abstraction is worse than duplication.

## Code Quality & Maintainability

Will the next person (or agent) who touches this code understand it?

- Cognitive load: how many things does a reader need to hold in their head simultaneously to understand this function?
- Scope hygiene: are variables, locks, and resources scoped as tightly as possible?
- Dead weight: commented-out code, unused imports, vestigial parameters
- Invariants: are they expressed in types, checked at runtime, or only documented in comments?
- Blast radius: if this function fails, what else goes down with it? Is failure contained or cascading?

## Simplicity & Proportionality

Is the complexity justified by what the code accomplishes?

- Are there new abstractions that only have one caller? Inline them
- Is there configuration for things that will never vary? Hardcode them
- Did someone write a framework where a function would do?
- Obsolete compatibility paths kept alive for transitional stability that's no longer needed. If the migration is done, delete the scaffolding
- Does the user experience justify the complexity? Every feature, control, and option should earn its place. Half-finished features are worse than missing ones.

Simpler is better unless simpler is wrong.

## Security

Are there attack vectors or unsafe assumptions?

- Injection: SQL, command, template, regex (ReDoS)
- Auth: are permissions checked at every entry point, not just the UI?
- Data exposure: are internal IDs, secrets, or PII leaked in logs or error messages?
- Input validation: is external input sanitized and bounded (length, range, format)?
- Trust boundaries: is data from one tenant/user allowed to influence another's execution?
- Path traversal: are user-controlled paths sanitized before filesystem access?
