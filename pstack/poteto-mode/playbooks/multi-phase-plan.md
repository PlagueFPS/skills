### Multi-phase or multi-PR plan

**You own the plan, not the code. The plan is a checklist an owner runs box by box and the operator audits from the evidence.** The plan is the deliverable. Do not implement.

1. When the change is one or two files with an obvious approach, skip the plan. Say so and stop.
2. Settle open questions by prototype before you write. Run `playbooks/prototype.md` for each. Keep the branch, the SHA, and the screenshots for Appendix A. Ask the operator only about a product or preference call that no run can settle. Give options (the **never-block-on-the-human** principle skill).
3. Explore in `delegate_task` workers with a self-contained brief that points at `pstack/agents/pstack-agent.md` and a named model role per the Subagents section (the **guard-the-context-window** principle skill). Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section. Each returns file pointers, conventions, test commands, and entry points. No inlined dumps.
4. Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under the project's `docs/`. Keep every heading and every sub-block in the order shown. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**. Pick between `playbooks/autopilot-full.md` and `playbooks/autopilot-stack.md` per the rule at the end of `playbooks/autopilot-stack.md`. A standing program takes `playbooks/orchestrate.md`.
5. Write under `/technical-writing` in full, then `/unslop`. The body is one Diátaxis mode, how-to. Appendices hold explanation and reference. Each heading states the task or the finding. No long dashes. No mid-sentence colons.
6. Check the plan against this list and fix every miss (the **encode-lessons-in-structure** principle skill). One PR section per PR between **Program checklist** and **Close the program**, each carrying the nine sub-blocks in order, **Depends on** through **Merge**; every verification block opens with the verification rule sentence; **Verify, live** names the `swarm workers` role and ten lanes with a screenshot and a pass predicate each; **Verify, perf** carries the Metric, Probe, Baseline, and Rule boxes; **Review gate** is the operator's review boxes or `None.` with none; the appendices follow **Close the program**, Prototype evidence included; no long dashes, curly quotes, or mid-sentence colons.
7. Hand back. Post the plan path and the checklist result, then stop. Execution starts on the operator's explicit go, under the execution playbook the plan names.

**Verification.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked (the **prove-it-works** principle skill). That sentence is the verification rule. Every verification block opens with it. The live block is mandatory. Ten lanes at the PR head drive the real surface through its control skill, per the **swarm** skill, on the `swarm workers` role from `pstack-models.md`, resolved through `orchestrator_capabilities`. Each lane is one box with a concrete scenario, the screenshot it saves, and its pass predicate. One lane is the **Regression lane against trunk.** It runs the same load-bearing scenario on trunk and head. If trunk does not have the feature, the lane records that fact and gates the behavior the diff adds plus the end state the user waits for instead of inventing a trunk result. The perf gate is dual-sided. Trunk and head must both produce the named metric. If trunk lacks the feature, also isolate the work the diff adds and set an absolute budget for that work plus the end-to-end state the user waits for. Do not claim a ratio between unlike scenarios. The perf block names the metric, the interleaved probe, the trunk baseline measured first, and the rule with the number that fails. A PR that changes an interaction is review-gated. The operator reviews it in chat with screenshots and a video before merge. A PR that changes no interaction writes `**Review gate.** None. <PR id> is not review-gated.` and no boxes under it.

**Control skill.** Pick it by surface. Browser, Electron, and web UIs use the `preview_*` tools. CLIs and TUIs use whatever driver skill the repo has. Native mobile uses the `device_*` tools. A PR that touches two surfaces gets lanes on both. A surface with no control skill is a risk in Appendix C, and its live block still names how each lane drives it.

````markdown
# <Program> plan
<Under ten lines. What changes, for whom, the rule the program enforces, and the PR ids in order.>

## How to read this
- **Program goals.** <One to three bullets. What this program achieves, and the rule or predicate that decides it is done.>
- **Scope.** <Rough number of PRs and time box. What is in and out of scope.>
- **Risk tier.** <Tier 1, 2, or 3, with the reasons.>
- **Execution playbook.** `playbooks/<autopilot-full | autopilot-stack | orchestrate>.md`
- **Rules.** No rebase after merge prep. Re-run Step 3 after any rebase or retarget. Every verified PR carries its verdict in the PR body.

## Program checklist
- [ ] PR 1. <One-line summary.>
- [ ] PR 2. <One-line summary.>

### Verdict and merge, for every PR
- [ ] A full swarm runs once, at the code-ready head. Another full swarm runs only for new behavior, a redesign, or a large new diff. A rebase, a merge-conflict resolution, or a minor fix gets a single verifier at the new head. Run each full swarm per `skills/swarm/SKILL.md`. One gates lane. The ten live lanes from the PR's **Verify, live** block. The perf lane from its **Verify, perf** block. Two or more audit lanes, each with its own focus, that read the diff and the receipts and distrust the PR body. The root audits the receipts in the merge-ready report before the verdict.
- [ ] Clean only when every lane is `PASS`. Findings go back to the owner, including a defect that a lane filed as a note. A new head gets a fresh verdict, except for results that stay valid under the patch-id rule in `playbooks/shipping.md`.
- [ ] <The merge or append rule from the execution playbook, with the patch-id rule from `playbooks/shipping.md`.>

### Boot recipe, for every live lane
Each live lane is a delegated worker at the PR head. Use `t3_thread_launch` with a `workspaceStrategy` for a lane that needs its own worktree. Drive the surface through `preview_*` for browser UIs and `device_*` for simulators.

- [ ] `git fetch origin <head-branch> && git checkout <head SHA>`.
- [ ] <Start the backend and the surface. Wait for ready.>
- [ ] <Deliver input only through the control skill's commands. Name the read-only diagnostics.>
- [ ] Save every screenshot to `/tmp/swarm-<pr-id>/worker-<n>/<slug>.png` and return the paths with the report.

## <Task as a verb phrase> (<PR id>)
**Depends on.** <PR id, or None.>

**Files.**
- [ ] Edit `<path>`.
- [ ] Create `<path>`.
- [ ] Delete `<path>`.

**Build.**
- [ ] <One change. Name the symbol and the file.>

**You see.**
- [ ] <One observable result, with the exact log line or screen state.>

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.
- [ ] <Test file and the case it gains.> Run `<command>`.

**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on the `swarm workers` role in `pstack-models.md` at the PR head, per the boot recipe.
- [ ] Lane 1. Regression lane against trunk. Run <the same load-bearing scenario> at trunk and head. If trunk lacks the feature, record that and gate <the behavior the diff adds plus the end state the user waits for>. Save `<slug>.png`. Pass when <predicate>.
- [ ] Lanes 2 to 10. Expand each into its own box in this shape. <Scenario.> Save `<slug>.png`. Pass when <predicate>.

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.
- [ ] Metric. <What is measured at both trunk and head. If trunk lacks the feature, also name the diff-added work and the end-to-end state the user waits for.>
- [ ] Probe. <Exact command or script. Interleaved, at least 5 runs each, throw away the first run.>
- [ ] Baseline. <Trunk metric measured first, with variance.>
- [ ] Rule. <Pass condition: "head <= trunk + N%" or "head <= <budget> ms". Fail on any statistically significant regression.>

**Review gate.**
- [ ] <Operator review items, or `None. <PR id> is not review-gated.`>

**Merge.**
- [ ] Squash merge to trunk with `gh pr merge <pr-id> --squash`.
- [ ] Retarget dependent PRs to trunk: `gh pr edit <next-pr-id> --base trunk`.

## Close the program
- [ ] Confirm all PRs are merged.
- [ ] Run the whole test suite against trunk.
- [ ] Post the close report with the audit trail.

## Appendix A. Prototype evidence
<Screenshots, SHAs, and measurements from Phase 2 prototypes.>

## Appendix B. Alternatives considered
<What was evaluated and why it was rejected.>

## Appendix C. Risks and open questions
<Known failure modes and how each is mitigated or monitored.>
````
