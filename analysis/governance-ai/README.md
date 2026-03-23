# Governance AI

Agentic governance workflow for Kyverno.

This workspace is intentionally separate from `analysis/static/`, which remains reserved for Python-based static analysis and should not be modified by this workflow.

## Context
This workflow is designed around a controlled feedback loop.
AI helps observe, analyze, propose, and review governance changes before a human approves anything.

## Core Principle

Kyverno remains the policy engine.
MCP remains the observation layer.
Agents provide role separation.

The workflow is:

1. observe
2. analyze
3. propose
4. review
5. validate in simulation
6. require human approval

No policy is applied automatically.

## Why This Exists

Clusters already emit governance signals through PolicyReports, violations, and repeated control failures.
The problem is not lack of data.
The problem is turning those signals into safe, traceable governance decisions.

`governance-ai` addresses that by separating responsibilities across specialized agents.

## Operating Model

### 1. Analyzer

Responsibilities:

- read Kyverno state through MCP
- identify friction by namespace and policy
- distinguish `NON_NEGOTIABLE` controls from `TUNABLE` controls
- produce an evidence-backed analysis report

Rules:

- uses Kyverno MCP
- does not apply changes
- does not produce final policy YAML

Primary output:

- `runs/<run-id>/01-analysis.md`

### 2. Policy Author

Responsibilities:

- read the analysis report as a contract
- generate Kyverno YAML proposals
- keep proposals traceable to backlog items from the analysis

Rules:

- does not query the cluster directly
- does not improvise outside the analysis contract
- does not relax `NON_NEGOTIABLE` controls
- does not apply changes

Primary output:

- `runs/<run-id>/generated-policies/`

### 3. Governance Reviewer

Responsibilities:

- review the analysis and generated YAML independently
- detect unsafe assumptions, excessive scope, and control weakening
- recommend whether proposals are ready for promotion

Rules:

- may optionally use MCP for spot validation
- does not apply changes

Primary output:

- `runs/<run-id>/02-review.md`

## Why The Role Separation Matters

If every agent talks directly to the cluster:

- traceability becomes weak
- authors can bypass analysis
- review is no longer independent

This architecture uses MCP as an observation boundary, not as a universal dependency.

Recommended usage:

- `Analyzer`: yes, use MCP
- `Policy Author`: no, do not use MCP
- `Reviewer`: optional, validation-only

## Directory Layout

```text
analysis/governance-ai/
  README.md
  prompts/
    catalog.md
  agents/
    analyzer.md
    policy-author.md
    reviewer.md
  runs/
    2026-03-20-101500/
      00-snapshot/
        .gitkeep
      01-analysis.md
      02-review.md
      run-summary.md
      generated-policies/
        .gitkeep
        001-require-resources-staged-rollout.yaml
        002-require-label-baseline-and-ownership.yaml
        003-restrict-hostpath-safe-correction.yaml
        004-generate-namespace-governance-baseline.yaml
      manifest.yaml
```

## Run Artifacts

Each run should produce a new artifact directory.

Use `runs/<run-id>/` where `<run-id>` is unique per execution.
Recommended format: `YYYY-MM-DD-HHMMSS`.
If the workflow runs twice on the same date, create two different directories.

Minimum expected outputs:

- `00-snapshot/`
  - optional exported reports or raw context
- `01-analysis.md`
  - analyzer findings
- `generated-policies/`
  - policy author proposals
- `02-review.md`
  - reviewer findings
- `run-summary.md`
  - concise explanation of the end-to-end workflow
- `manifest.yaml`
  - run status and artifact pointers

## Non-Negotiable Guardrails

These rules are part of the design, not optional conventions:

- never modify `analysis/static/` from this workflow
- never apply policies automatically
- never let the policy author bypass the analyzer contract
- never relax `NON_NEGOTIABLE` controls just to reduce friction
- always keep a human approval checkpoint before promotion

## Recommended Workflow

### Step 1. Analyze the cluster

The analyzer reads Kyverno state and produces:

- total violation counts
- top violated policies
- hotspot namespaces
- `NON_NEGOTIABLE` vs `TUNABLE` classification
- action recommendations
- a YAML generation backlog

Artifact:

- `01-analysis.md`

### Step 2. Generate policy proposals

The policy author reads the analysis report and generates proposal files only for approved backlog items.

Typical proposal categories:

- staged rollout for high-friction tunable controls
- better scoping or messaging
- safe fixes for noisy policy behavior
- namespace baseline templates

Artifact:

- `generated-policies/*.yaml`

### Step 3. Review proposals

The reviewer checks:

- consistency with the analysis
- preservation of `NON_NEGOTIABLE` controls
- rollout safety
- placeholder usage
- scope correctness

Artifact:

- `02-review.md`

### Step 4. Validate in simulation

Use simulation to test policy behavior without changing the cluster.

Typical validation approach:

```bash
kyverno apply <policy.yaml> --cluster --context <context>
```

This is validation only.
It does not apply the policy to the cluster.

### Step 5. Human approval

A person decides what gets promoted, revised, or discarded.

This workflow ends before any automatic `kubectl apply`.

## Example Run

The run under `runs/2026-03-20/` demonstrates the complete workflow.
For future executions, prefer timestamped directories such as `runs/2026-03-20-101500/`.

Highlights:

- analyzed current Kyverno violations through MCP
- identified `observability` as the main hotspot
- generated four policy proposals
- reviewed the proposals independently
- validated key policies in simulation only

Simulation results from that run:

- `001-require-resources-staged-rollout.yaml`: `pass: 8`, `fail: 29`, `error: 0`
- `002-require-label-baseline-and-ownership.yaml`: `pass: 11`, `fail: 32`, `error: 0`
- `003-restrict-hostpath-safe-correction.yaml`: `pass: 47`, `fail: 12`, `error: 0`

Most important result:

- the `hostPath` correction removed noisy evaluation errors in simulation and now behaves like a real control with genuine failures only

See:

- `runs/2026-03-20/01-analysis.md`
- `runs/2026-03-20/02-review.md`
- `runs/2026-03-20/run-summary.md`

## Operating Framing

Useful way to explain this approach:

- the cluster speaks through violations
- the analyzer interprets those signals
- the policy author turns decisions into YAML
- the reviewer protects against unsafe automation
- the human remains the approval boundary

This is not "AI changes production."

This is "AI helps structure the governance loop so humans can move faster with better evidence."

## What This Approach Is Not

It is not:

- autonomous production policy application
- blind self-modification
- a replacement for platform ownership
- a reason to weaken security baselines

## Files To Read First

If you want the shortest path into this workspace:

1. `prompts/catalog.md`
2. `agents/analyzer.md`
3. `agents/policy-author.md`
4. `agents/reviewer.md`
5. `runs/2026-03-20/run-summary.md`

## Final Rule

Agentic governance is only useful if it remains explainable, reviewable, and controllable.

If a workflow cannot show:

- where the evidence came from
- why a proposal was generated
- who reviewed it
- and who approved it

then it is automation without governance.
