# Governance AI Prompt Catalog

Prompt catalog for the `governance-ai` workflow.

This catalog replaces the old MCP-only framing with an agentic operating model.

## Architecture Principle

MCP is an observation layer, not a universal dependency.

- `Analyzer`: uses Kyverno MCP
- `Policy Author`: does not use MCP
- `Reviewer`: may use MCP only for validation

## Agent Flow

1. `Analyzer`
   - reads current governance state
   - classifies friction and risk
   - writes the analysis contract

2. `Policy Author`
   - consumes only the analysis contract
   - generates YAML proposals
   - does not inspect the cluster directly

3. `Reviewer`
   - checks consistency, safety, and rollout quality
   - optionally validates assumptions against MCP

## Conventions

- ID: `GAI-PXX`
- Language: English
- Scope: analysis, recommendation, and proposal
- Default rule: do not apply changes
- Every workflow execution must create a new run directory under `runs/<run-id>/`
- `<run-id>` must be unique per execution, preferably `YYYY-MM-DD-HHMMSS`
- Never reuse `runs/<date>/` when the workflow is executed more than once on the same day
- Placeholders: `{namespace}`, `{policy}`, `{context}`, `{resource_kind}`, `{resource_name}`, `{business_unit}`, `{owner_team}`, `{environment}`, `{risk_tolerance}`, `{expiration_date}`

## Non-Negotiable Baseline

Treat these as security baseline controls:

- `disallow-privileged-containers`
- `disallow-host-namespaces`
- `disallow-host-path`
- `require-run-as-non-root-user`
- `require-run-as-nonroot`
- `require-read-only-root-filesystem`
- `restrict-capabilities`
- `restrict-seccomp-strict`
- `require-network-policy`
- `disallow-latest-tag`
- `disallow-host-ports`

Infer `NON_NEGOTIABLE` when names vary using keywords:

- `cis`
- `pod-security`
- `psa`
- `security`
- `seccomp`
- `capabilit`
- `privileged`
- `hostpath`
- `host-namespace`
- `non-root`
- `read-only-root`

## Recommended Prompt Sequence

1. `GAI-P01` cluster baseline
2. `GAI-P02` friction threshold
3. `GAI-P03` non-negotiable classifier
4. `GAI-P04` namespace deep dive
5. `GAI-P05` business recommendations and backlog
6. `GAI-P06` YAML proposal generation
7. `GAI-P07` review and approval recommendation

---

## GAI-P01 - The Cluster Speaks

Agent:
- `Analyzer`

Objective:
- show cluster-wide friction patterns by namespace and policy

Prompt:
```text
Analyze current Kyverno violations cluster-wide.
Group them by namespace and by policy.
Show:
- total violations
- fail vs error distribution
- top 3 most violated policies
- which namespace concentrates more issues

Write the report to a newly created unique run directory under `runs/<run-id>/`.
If today already has a previous run, create a new timestamped directory instead of reusing it.

Do not apply changes.
```

Expected output:
- cluster-wide summary with namespace and policy ranking

Suggested framing:
- "Violations are not noise. They are signals."

---

## GAI-P02 - Friction Threshold

Agent:
- `Analyzer`

Objective:
- detect systemic friction when a policy crosses a meaningful threshold

Prompt:
```text
For each namespace, count violations by policy.
If any policy exceeds 5 violations in the same namespace,
recommend whether:
- keep enforced,
- temporarily switch to audit,
- redesign the rule.

For each recommendation, explain whether the issue is:
- workload remediation,
- rollout friction,
- policy design problem.

Write the report to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Do not apply changes.
```

Expected output:
- namespace and policy list with decision and reasoning

Suggested framing:
- "We are not blaming workloads; we are detecting systemic friction."

---

## GAI-P03 - Non-Negotiable Classifier

Agent:
- `Analyzer`

Objective:
- separate security baseline controls from tunable controls

Prompt:
```text
Analyze current Kyverno violations and classify each violated policy as:
- NON_NEGOTIABLE
- TUNABLE

Use the documented non-negotiable baseline and keyword inference.

For each NON_NEGOTIABLE policy:
- provide count
- affected namespaces
- affected resource kinds
- remediation strategy that does NOT relax enforcement

For each TUNABLE policy:
- provide count
- tuning options such as:
  - better match or exclude granularity
  - better messages
  - staged rollout
  - temporary Audit with expiration date

Write the report to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Do not apply changes.
```

Expected output:
- classification table and prioritized remediation strategy

Suggested framing:
- "Security baselines are non-negotiable; friction is addressed through workload remediation and guided rollout."

---

## GAI-P04 - Namespace Deep Dive

Agent:
- `Analyzer`

Objective:
- explain whether repeated violations indicate a one-off exception or structural issue

Prompt:
```text
Analyze violations in namespace {namespace}.

Explain:
- the most repeated patterns
- whether the issue looks isolated or systemic
- whether hostPath, privileged mode, or missing limits create real risk
- recommended action strategy

Classify the namespace as:
- isolated exception
- rollout friction
- structural design issue

Write the report to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Do not apply changes.
```

Expected output:
- focused risk and action assessment for the namespace

---

## GAI-P05 - Recommendations and Backlog

Agent:
- `Analyzer`

Objective:
- turn findings into a structured generation backlog for the next agent

Prompt:
```text
Using Kyverno violation data, produce:
1) top friction policies with impact:
   - count
   - affected namespaces
   - affected resources
   - sample violation reason
2) recommendations per policy:
   - if NON_NEGOTIABLE: do not relax; provide remediation path and rollout plan
   - if TUNABLE: propose safer tuning options
3) YAML Generation Backlog entries with:
   - backlog_id
   - source_policy
   - target_namespaces
   - action
   - constraints
   - rationale

Write the report to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Do not generate final YAML in this step.
Do not apply changes.
```

Expected output:
- concise report plus structured backlog for the Policy Author

Suggested framing:
- "From raw violations to reusable governance patterns aligned to operational reality."

---

## GAI-P06 - YAML Proposal Generation

Agent:
- `Policy Author`

Objective:
- generate YAML proposals from the analysis backlog only

Prompt:
```text
Using the analysis report as the only decision contract, generate Kyverno YAML proposals.

Rules:
- write outputs under the current execution's unique `runs/<run-id>/generated-policies/` directory
- if a run already exists for today's date, create a new timestamped run directory and use that one
- do not query the cluster directly
- do not invent recommendations outside the report
- do not relax NON_NEGOTIABLE controls
- only generate YAML for backlog items explicitly described in the analysis
- for TUNABLE controls, prefer:
  - scoped matching
  - clearer messages
  - staged rollout
  - temporary Audit with explicit expiration guidance

Output:
- one YAML file per proposal
- short rationale per file

Do not apply changes.
```

Expected output:
- YAML files under `generated-policies/`

Suggested narrative:
- "The author agent does not improvise. It implements the governance contract."

---

## GAI-P07 - Review and Approval Recommendation

Agent:
- `Reviewer`

Objective:
- validate that generated YAML matches the analysis and preserves risk posture

Prompt:
```text
Review the analysis report and the generated YAML proposals.

Validate:
- policy proposals match the analysis recommendations
- NON_NEGOTIABLE controls were not weakened
- tunable policies include safer rollout logic where applicable
- generated policies are specific enough for the target namespaces
- assumptions are explicit

Write the review to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Optionally use Kyverno MCP only for spot validation.

Do not apply changes.

Output sections:
- Review Summary
- Findings
- Risks
- Approval Recommendation
```

Expected output:
- independent review report

---

## GAI-P08 - Executive Trend Report

Agent:
- `Analyzer`

Objective:
- translate repeated patterns into governance health status for leadership

Prompt:
```text
Assume the last 7 days show the same violation patterns.
Classify policies as:
- Healthy
- Friction-based
- Structural design issue

Provide a short governance report with:
- current state
- main risks
- priority actions
- what should not be relaxed

Write the report to the current execution's unique `runs/<run-id>/` directory.
Do not reuse a same-day directory from a previous run.

Do not apply changes.
```

Expected output:
- short executive governance report

---

## Workflow Framing

This catalog supports a workflow with a clear control narrative:

- the cluster emits signals
- the analyzer interprets them
- the policy author proposes changes
- the reviewer stops unsafe drift
- the human remains the approval point
