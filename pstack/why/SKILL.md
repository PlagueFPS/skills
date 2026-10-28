---
name: why
description: "Use for 'why does X work this way', 'why we picked Y', design rationale, regressions, postmortems, or data-backed thresholds. Discovers available MCPs and queries each evidence category (source control, issue tracker, long-form docs, real-time chat, infrastructure observability, error tracking, product analytics warehouse) in parallel, then returns a cited read on decisions and tradeoffs. Use how for runtime behavior."
disable-model-invocation: true
---

# Why

Investigate the motivation and intent behind code.

Companion to the `how` skill. `how` answers what the code does and how it works. `why` answers what forces led to its shape.

Each delegation below names a role line in `pstack-models.md`. Resolve it through `orchestrator_capabilities` and pass that provider and model to `delegate_task`. Never hardcode a slug. If the line or the file is missing, use the session default and say so. Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section of the **poteto-mode** skill.

## Operating Posture

Operate as a **careful, cautious, and precise investigator**. Be honest about what you know vs what you're inferring. Read `references/epistemics.md` for the full confidence framework and phrasing guide. The synthesizer must follow it.

## Step 1. Understand the Target and the Question

Parse what the user is asking. The **target** is usually a chunk of code, a pattern, a feature, or a named design decision. The **question** is usually a design rationale, a tradeoff, a motivating edge case, an external constraint, dead code, or a broad history sweep.

If the target is vague ("why do we do it this way?" with no clear referent), make your best guess from conversation context (open files, recent edits, selection, what was just discussed). State your interpretation briefly so the user can redirect if you're off, then proceed.

## Step 2. Establish the Code Anchor

Before delegating investigators, anchor the investigation in concrete code. You need:

- The relevant file path(s) and line range(s)
- The key symbols (function names, class names, constants)
- An initial commit list. The last few commits touching the target.
- PR numbers from merge commits (pattern `(#1234)` in the subject line)

Build this inline.

```bash
# Blame target lines for last-touch commits
git blame -L <start>,<end> <file>

# Full file history, with patches, through renames
git log --follow -p -- <file>

# Last N commits touching the file, PR numbers visible
git log --oneline -20 -- <file>

# Extract PR numbers from a commit message
git log -1 --format=%B <commit>
```

Pull PR bodies and discussion via `gh` for any substantive commits:

```bash
gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews
```

Capture this as seed context (file paths, symbols, commits, PR numbers, linked ticket IDs). Pass it to the investigators.

## Step 3. Delegate Parallel Investigators (default posture)

**Default to the full parallel investigation.**

### Discovery

Before delegating, inventory the MCP servers from the tools this session exposes. Group tools by server prefix and read tool names and descriptions.

Map each available MCP to one evidence category:

1. Source control history
2. Issue / ticket tracker
3. Long-form documents
4. Real-time team chat
5. Infrastructure observability
6. Error tracking
7. Product analytics warehouse

For any category with no corresponding MCP available in this session, do not fail. Mark that category as `NO_MCP_AVAILABLE` in the seed context, note it in the handoff to the synthesizer, and proceed with the remaining categories.

### Delegation

Spawn one investigator per available category simultaneously, each with `mode: "async"` and the model from the `why investigators` role. Pass each its category's playbook from `references/sources/<category>.md` along with the code anchor and seed context. Collect completion reports according to the returned `next`; do not poll running delegates.

## Step 4. Synthesize

Spawn one synthesizer on the `why synthesizer` role with `references/synthesizer-prompt.md`. Pass it the question, code anchor, and all investigator findings.

## Step 5. Output

Present the synthesized brief, citing sources, evidence confidence, and open questions.
