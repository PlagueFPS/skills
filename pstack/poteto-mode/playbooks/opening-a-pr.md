### Opening a PR

**You own the PR body. Write it to a human reviewer standard, keep the diff small, and never let opening a PR stall the next unit.**

Work from a git worktree off trunk, and keep unrelated work out of it. Rebase into small, landable commits. Run the **unslop** skill over the diff before commit, and the **no-comments** skill before you write the body.

Title: `type(scope): subject`, naming a real symbol when one carries the change. Body: a one-minute briefing under 40 lines with these `##` headings in order, dropping empty ones: `## Why`, `## What changed`, `## Scope`, `## Tradeoffs` (only rejected alternatives a reviewer would otherwise ask about), `## Blast Radius`, `## Verification`.

Stack follow-ups by base branch. Open PRs ready with `gh pr create` without `--draft`, then call `link_pull_request` with the full URL for every layer of a stack. Never require Graphite (`gt`). Opening a PR does not start a babysit.
