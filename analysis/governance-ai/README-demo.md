# Governance AI Workflow Overview

## The Idea

Clusters already tell us where governance is breaking down.
They do it through violations, PolicyReports, drift, and repeated control failures.

The problem is not collecting more signals.
The problem is turning those signals into safe decisions.

That is what `governance-ai` is for.

## What This Workflow Shows

This workflow shows an agentic model for Kyverno governance:

1. the cluster emits signals
2. an analyzer interprets them
3. a policy author proposes changes
4. a reviewer challenges those proposals
5. validation happens in simulation
6. a human remains the approval point

This is the important boundary:

No policy is applied automatically.

## What “Self-Healing” Means Here

It does not mean:

- AI changing production on its own
- auto-applying policies
- removing human control

It means:

- governance loops become faster
- analysis becomes more structured
- proposals become traceable
- review becomes explicit

This is not blind automation.
It is controlled adaptation.

## The Three Agents

### Analyzer

The analyzer is the only agent that reads Kyverno state through MCP.

Its job is to answer:

- what policies create the most friction
- which namespaces are the hotspots
- which controls are non-negotiable
- which controls are tunable
- what should be remediated versus redesigned

Output:

- `runs/<run-id>/01-analysis.md`

### Policy Author

The policy author does not inspect the cluster directly.

It reads the analysis report as a contract and generates YAML proposals from that contract only.

That matters because it prevents the author from improvising outside the evidence.

Output:

- `runs/<run-id>/generated-policies/*.yaml`

### Reviewer

The reviewer is the control point.

It checks:

- whether the generated YAML matches the analysis
- whether non-negotiable controls were weakened
- whether rollout scope is too broad
- whether the policies are safe enough to validate further

Output:

- `runs/<run-id>/02-review.md`

## Why This Architecture Matters

If every agent talks directly to the cluster, you lose the most important thing:

traceability

Then the system becomes hard to explain:

- who decided what
- based on which evidence
- reviewed by whom
- approved by whom

This design avoids that.

MCP is used as an observation layer, not as a shortcut for every agent.

## The Workflow

### 1. Analyze

The analyzer reads current Kyverno signals and creates a report.

It identifies:

- total violations
- top violated policies
- hotspot namespaces
- `NON_NEGOTIABLE` controls
- `TUNABLE` controls
- a YAML generation backlog

### 2. Propose

The policy author turns that backlog into YAML proposals.

Examples:

- staged rollout for resource requirements
- better label baselines
- safer correction of noisy hostPath behavior
- namespace baseline templates

### 3. Review

The reviewer checks the proposals and looks for:

- unsafe weakening of controls
- excessive rollout scope
- unresolved placeholders
- technical and governance risks

### 4. Validate in Simulation

Policies are tested in simulation only.

For example:

```bash
kyverno apply <policy.yaml> --cluster --context <context>
```

This validates policy behavior without applying anything to the cluster.

### 5. Human Approval

This is where the workflow stops unless a human decides to continue.

That is intentional.

## Example Run

Each execution must create a new run directory under `runs/<run-id>/`.

Recommended format:

- `runs/YYYY-MM-DD-HHMMSS/`

The example run lives under:

- `runs/2026-03-20/`

What happened in that run:

- the analyzer found `285` active Kyverno violations
- `observability` was the main hotspot with `129`
- the top friction policies were:
  - `disallow-latest-tag`
  - `require-requests-limits`
  - `restrict-hostpath`
- the policy author generated four proposals
- the reviewer marked the set as `needs_revision`
- key policies were then validated in simulation

Simulation highlights:

- `001-require-resources-staged-rollout.yaml`: `pass: 8`, `fail: 29`, `error: 0`
- `002-require-label-baseline-and-ownership.yaml`: `pass: 11`, `fail: 32`, `error: 0`
- `003-restrict-hostpath-safe-correction.yaml`: `pass: 47`, `fail: 12`, `error: 0`

Most important result:

The corrected `hostPath` policy removed noisy runtime-style errors in simulation and behaved like a real control with genuine failures only.

## Key Takeaways

Violations are not noise.
They are signals.

Agentic governance works when:

- observation is separate from authorship
- authorship is separate from review
- validation is separate from approval

That separation is what makes the system trustworthy.

## The Real Message

The future is not clusters governing themselves without humans.

The future is clusters with governance loops that are:

- observable
- explainable
- reviewable
- accelerated by specialized AI agents

## Files To Open For A Compact Walkthrough

If you want a compact walkthrough:

1. `runs/2026-03-20/01-analysis.md`
2. `runs/2026-03-20/generated-policies/003-restrict-hostpath-safe-correction.yaml`
3. `runs/2026-03-20/02-review.md`
4. `runs/2026-03-20/run-summary.md`

## Final Note

This is not “AI writes policies and changes production.”

This is:

AI helps structure the governance loop so humans can move faster with better evidence.
