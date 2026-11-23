# Upstream snapshot

Source: https://github.com/cursor/plugins/tree/7a583913eb1b8d1a0ee76753d1a2cf072e7b54f9/pstack/skills

Synced through `7a583913eb1b8d1a0ee76753d1a2cf072e7b54f9` on 2026-11-23, including PRs #1249, #1283, #1284, and #1292. The previous sync was `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7`.

Local adapters use T3 delegation, thread history, scheduling, PR watches, secrets, and inline rendering. Model roles remain in project `pstack-models.md` or global `~/.agents/pstack-models.md`. Native T3 PR watches and worktree tools replace upstream's watch-pr scripts and Cursor transcript auditor; upstream deleted the plan checker, so no scripts are bundled from that tool directory. Local agent briefs and T3-specific references are retained, and `poteto-mode/worker.md` is passed to delegates the same way upstream passes it to Cursor subagents. Origin, `/loop`, `cursor-team-kit`, and Cursor's Task tool are not copied. Upstream's Cursor model slugs (Fable, Opus, Gemini) are not copied; `setup-pstack` maps their role defaults and effort levels (capped at xhigh) onto whatever `orchestrator_capabilities` reports.
