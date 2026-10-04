# Central Agent Skills Repository

This repository holds central skills loaded dynamically across all AI coding assistants and models, including **T3 Code**, **Antigravity (Gemini)**, **Claude Code**, **Cursor**, **Codex**, and **OpenCode**.

## Directory Layout

Each skill has its own subdirectory containing a `SKILL.md` file:

```text
skills/
├── effect/
│   ├── SKILL.md
│   └── references/
├── javascript-testing-expert/
│   └── SKILL.md
└── <new-skill>/
    └── SKILL.md
```

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

## Global Provider Links

This repository is symlinked to the following discovery paths:
- **Antigravity / Gemini:** `~/.gemini/config/skills` & `~/.gemini/antigravity-cli/skills`
- **Claude Code:** `~/.claude/skills`
- **Cursor:** `~/.cursor/skills`
- **OpenAI Codex:** `~/.codex/skills`
- **OpenCode:** `~/.config/opencode/skills`
- **Standard Agent Skills:** `~/.agents/skills`
- **Convenience Link:** `~/skills` -> `~/code/skills`
