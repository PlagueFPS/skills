### Opening a PR

**You own the PR body. Write it to a human reviewer standard, keep the diff small, and never let opening a PR stall the next unit.**

1. Strip comments via the **no-comments** skill before you write the body.
2. Strip AI prose tells via the **unslop** skill over your draft of the body.
3. Commit ordered units. Each commit message follows `type(scope): summary` under `/technical-writing`.
4. Open the PR through the resolved forge.

**Structure.** Open the PR with this structure. Every section stands on facts you verified. Never write placeholders such as `TODO` or `fill in later`. Never describe file-by-file what the diff shows, and never re-narrate your debugging session.

Put each section under a `##` heading, not a bold lead-in, so the sections stand apart. Use these sections in order. Drop a section when it has nothing to say.

- `## Why` gives the problem and the approach in one to three short sentences. Do not list SHAs or rebase genealogy. Do not add a "based on main" preamble.
- `## What changed` has one to three short bullets. Name a real symbol or path only when it carries the change. Name both sides of a rename or retarget.
- `## Scope` always names what the PR covers and what it deliberately leaves out, for example a related follow-up or a known gap. Use one to three short items. Do not list symbols or paths, and do not write a file-by-file essay.
- `## Tradeoffs` names only rejected alternatives that a reviewer would otherwise ask about. Skip this section when there was no real choice.
- `## Blast Radius` gives one or two sentences on who or what the change touches and why that is safe or risky. If main is red, state the cost of leaving it red.
- `## Verification` has one to three bullets. Each bullet names a real run path and its outcome. For a performance change, report one primary number with its unit in `before → after` form. Link the arena or swarm directory for the remaining evidence. Do not include sample-size methodology, swarm recitals, or metric tables.

After the sections, attach videos or screenshots when they prove a claim. Full SHAs, swarm or arena lane recitals, lever-correction essays, file-by-file checklists, and "CLEAN" verdicts go in a linked artifact, not the body.

**Forge.** GitHub CLI (`gh`) is the forge. Use it for create, edit, view, watch, and merge. Never require Graphite (`gt`).

**Built-in PR tool.** T3's built-in PR tool is `link_pull_request`, and it registers a PR rather than creating one. Call it with the full URL the moment a PR opens, and link every layer of a stack; a PR created through `gh` is untracked until it is linked. `list_thread_pull_requests` returns the stack bottom to top. Create, edit, retarget, and mark ready through `gh`.

**Size and stacks.** Prefer five narrow PRs to one large PR. A stack is a base-branch chain. The root PR targets trunk. Each child branch rebases onto its parent's exact tip and its PR targets the parent branch. As a parent merges, move its child onto trunk per `playbooks/shipping.md` step 4. Create a child with `gh pr create --base <parent-branch>`, and retarget an existing child with `gh pr edit <pr> --base <parent-branch>`. Branch from trunk only for independent work. Rebase on trunk before substantial stack work.

**Readiness.** Open every PR ready, never as a draft. With `gh`, omit `--draft`. If a PR still opens as a draft, run `gh pr ready <number>`. Run `gh pr view <number>` before you refer to PR status.

**Babysit.** Opening a PR does not start a babysit. Post the URL and keep building. Finish the phase or stack first. Run a separate babysit pass only when the user asks for one after the whole stack exists. That pass arms `watch_pull_request` and ends the turn; T3 wakes the thread when checks finish, a comment lands, or the branch conflicts. A babysit for each new PR stalls the build and spends checks on commits later waves restart. Push back when feedback drifts from intent.
