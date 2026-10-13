# Central Agent Skills Repository

This repository holds central skills loaded dynamically across all AI coding assistants and models, including **T3 Code**, **Antigravity (Gemini)**, **Claude Code**, **Cursor**, **Codex**, and **OpenCode**.

## Directory Layout

Each skill has its own subdirectory containing a `SKILL.md` file:

```text
skills/
├── effect/
│   ├── SKILL.md
│   └── references/
├── effect-service-design/
│   ├── SKILL.md
│   ├── LICENSE
│   ├── agents/
│   └── references/
├── javascript-testing-expert/
│   └── SKILL.md
└── <new-skill>/
    └── SKILL.md
```

The `effect-service-design/` skill comes from [dmmulroy/skills at commit 8603380](https://github.com/dmmulroy/skills/tree/8603380821fee6a77c82639f364ce8fe4f5a92be/effect-service-design).
It includes the audit reference, agent metadata, and [upstream MIT license](effect-service-design/LICENSE).

## Adding a New Skill

1. Create a directory for your skill:
   ```bash
   mkdir -p <skill-name>
   ```
2. Create `<skill-name>/SKILL.md` with YAML frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: One-sentence description of what this skill does.
   user-invocable: true
   ---

   Instructions and context for the agent when this skill is invoked...
   ```
3. Commit and push:
   ```bash
   git add <skill-name>
   git commit -m "feat: add <skill-name> skill"
   git push
   ```

## Automatic Sync

To ensure new skills are automatically pulled and made immediately available across all AI harnesses (T3 Code, Claude Code, Cursor, Codex, OpenCode, Gemini):

1. **Install the background sync timer & CLI link:**
   ```bash
   ./scripts/sync-skills.sh --install
   ```
   This does the following:
   - Symlinks `skills-sync` into `~/.local/bin/skills-sync`
   - Installs a systemd user timer (`skills-sync.timer`) that checks `origin/main` every 2 minutes and fast-forwards `main` in `~/code/skills`
   - Configures a git `post-merge` hook so local merges automatically verify harness symlinks

2. **Check status anytime:**
   ```bash
   skills-sync --status
   ```

3. **Manual sync:**
   ```bash
   skills-sync
   ```

## Global Provider Links

This repository is symlinked to the following discovery paths:
- **T3 Code / Antigravity:** `~/.t3/userdata/providers/antigravity/*/config/skills` & `~/.gemini/config/skills`
- **Claude Code:** `~/.claude/skills`
- **Cursor:** `~/.cursor/skills`
- **OpenAI Codex:** `~/.codex/skills`
- **OpenCode:** `~/.config/opencode/skills`
- **Standard Agent Skills:** `~/.agents/skills`
- **Convenience Link:** `~/skills` -> `~/code/skills`
