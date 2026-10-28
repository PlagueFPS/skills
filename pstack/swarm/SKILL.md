---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
disable-model-invocation: true
---

# Swarm

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker model from the `swarm workers` line in `pstack-models.md`, resolved through `orchestrator_capabilities`. If the file or that line is missing, run `setup-pstack`. For `auto` or `inherit-parent`, omit `target` so the workers run on the parent model. If `delegate_task` rejects the configured provider or model, report it and wait for an authorized choice; do not silently switch. For a model race, name each arm's model up front. Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section of the **poteto-mode** skill.
4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Spawn all N workers in one turn with `delegate_task`, `mode: "async"`, and the step 3 target, left unset for `auto` or `inherit-parent`. Use `delegate_task` with `isolation: "worktree"` when the worker needs a separate checkout or branch. One writer per worktree.

Every brief stands alone. Child agents get only the brief, never the parent's context. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Follow each delegate result's `next`; completion wakes this thread. Do not poll or schedule checks of running delegates. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with a result table, issue one-liners, gaps or dropouts, and the race rule when used.
