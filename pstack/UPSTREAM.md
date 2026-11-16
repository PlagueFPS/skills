# Upstream snapshot

Source: https://github.com/cursor/plugins/tree/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/skills

Synced through `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7` on 2026-11-16, including PR #1236. The previous sync was `b1695c2019b650ca5d4a66a6a6d805233c806d6d`.

Local adapters use T3 delegation, thread history, scheduling, PR watches, secrets, and inline rendering. Model roles remain in project `pstack-models.md` or global `~/.agents/pstack-models.md`. Native T3 PR watches and worktree tools replace upstream's watch-pr scripts and Cursor transcript auditor; only the plan checker is bundled from that tool directory. Local agent briefs and T3-specific references are retained. Upstream's Cursor model slugs (Fable, Opus, Gemini) are not copied; `setup-pstack` maps their role defaults and effort levels onto whatever `orchestrator_capabilities` reports.
