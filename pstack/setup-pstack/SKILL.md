---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes pstack-models.md, which overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
disable-model-invocation: true
---

# Setup pstack

Write `pstack-models.md`, a file that sets pstack's model per role. Default location is the current project root. Offer `~/.agents/pstack-models.md` as the global option, and ask which one. A project file wins over the global one.

## Steps

### 1. Detect available models

Call `orchestrator_capabilities`. It lists the providers and models you can pass to `delegate_task` in this session, custom models included, with each one's provider instance ID and any reasoning options. That is the only source. If it returns nothing, stop and tell the user. Never write a provider or model it did not return. `inherit-parent` is always valid even though it is not a detected model.

### 2. Load current state

The roles are the labels shown in step 5. If `pstack-models.md` already exists at the chosen location, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from the defaults in step 3(b). A line whose role is not in step 5, such as `hardest tasks`, `architect runners`, `reflect tooling`, or `why investigators`, is from a retired role. Drop it.

A file without the `# defaults: 3` line comes from an older setup. That setup wrote a line for every role, so some of its values are old defaults, not choices. Before step 3, replace these values:

- A `# budget: unlimited` line becomes `large`, because no role runs above `xhigh`.
- Any entry above `xhigh` effort drops to `xhigh`.
- If the file has no `# defaults: 2` line either, the older setup gave code roles the fastest coding model. Move each of `feature, refactoring`, `bug-fix`, `perf-issue`, and `hillclimb` that still holds that older default to its step 3(b) default.

Every other value is the user's choice and stays, including every `inherit-parent` value. Tell the user which values you replaced.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Ask plainly in the thread. Offer these three options with these exact labels, and name the current budget when the file records one. With no file, say that `large` matches the skill defaults.

- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table. On a fresh run, give code roles (`feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`) and `judgment and prose` a strong general model. Give `swarm workers` a fast strong model. Fill each panel role with one entry per distinct vendor detected, up to three, so a panel stays diverse. Never default a role to the most capable, slowest model. It runs outside a panel only when the user names it for a task, per the Subagents section of the **poteto-mode** skill. On a re-run, keep any role the user changed.

When the catalog exposes reasoning options for a model, each role has a target effort, which is its base effort moved by the budget. The base is `high` for `swarm workers` and every panel entry, and `xhigh` for every other role. `large` keeps the base, `medium` lowers it one step, and `small` lowers it two steps, on the ladder `xhigh` > `high` > `medium` > `low`. No role runs above `xhigh`, and a target at the bottom of the ladder stays there. Set each real entry's effort option to its role's target. Most roles have an `xhigh` base, and each budget label names where those land. If the model does not expose the target, use the highest option at or below it, else mark the role as needing a choice. When a model offers a fast mode, keep it on for every role that model fills. `inherit-parent` does not change. When the catalog exposes no reasoning options, map roles only and drop effort tokens; the budget label is still recorded.

**(c) Show the roles and confirm.** Show every role with its model, marking any entry not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models at `xhigh` or below plus `inherit-parent` (the role runs on the parent thread's model, so omit the model in `delegate_task`) as the options. For panel roles (arena runners, interrogate reviewers) the value is a list, and one `delegate_task` runs per entry, `inherit-parent` entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena runs one judge. It tries only values from a vendor other than the parent's, in list order, so order it by preference. Two models from the same vendor count as one vendor. An `inherit-parent` value never judges. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real entry written must be in the `orchestrator_capabilities` result, under the provider instance it came from, and at `xhigh` or below. `inherit-parent` always passes. If a chosen entry is not available, stop and ask again.

### 5. Write the file

Write `pstack-models.md` with the `# defaults: 3` line, a `# budget` line with the chosen label and the effort that label names, and one line per role, using the same labels poteto-mode uses. Write each entry as `<providerInstanceId>/<model>`, followed by its effort option in parentheses when step 3(b) set one. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` as a value: the role runs on the parent thread's model (omit the delegate_task model). Entries in a panel list still count toward its fan-out.
# defaults: 3
# budget: large (xhigh)
feature, refactoring: <providerInstanceId>/<model> (<effort>)
bug-fix: <providerInstanceId>/<model> (<effort>)
perf-issue: <providerInstanceId>/<model> (<effort>)
hillclimb: <providerInstanceId>/<model> (<effort>)
judgment and prose: <providerInstanceId>/<model> (<effort>)
arena runners: <entry>, <entry>, <entry>
arena cross-judge pool: <entry>, <entry>
swarm workers: <providerInstanceId>/<model> (<effort>)
interrogate reviewers: <entry>, <entry>, <entry>
```

### 6. Confirm

Tell the user the file was written, where, and that it applies to new sessions. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
