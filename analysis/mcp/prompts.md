# Kyverno MCP Prompt Catalog

Official prompt catalog for governance analysis using `kyverno-mcp`.

## Conventions

- ID: `KYV-PXX`
- Language: English
- Focus: analysis and recommendation, no change execution (unless explicitly requested)
- Placeholders: `{namespace}`, `{policy}`, `{context}`, `{resource_kind}`, `{resource_name}`, `{business_unit}`, `{owner_team}`, `{environment}`, `{risk_tolerance}`
- Non-negotiable policy baseline (CIS/security): `disallow-privileged-containers`, `disallow-host-namespaces`, `disallow-host-path`, `require-run-as-non-root-user`, `require-run-as-nonroot`, `require-read-only-root-filesystem`, `restrict-capabilities`, `restrict-seccomp-strict`, `require-network-policy`, `disallow-latest-tag`, `disallow-host-ports`
- Keywords to classify non-negotiable when names vary: `cis`, `pod-security`, `psa`, `security`, `seccomp`, `capabilit`, `privileged`, `hostpath`, `host-namespace`, `non-root`, `read-only-root`

## Recommended Demo Sequence

1. `KYV-P01` (cluster baseline)
2. `KYV-P02` (friction threshold)
3. `KYV-P11` (non-negotiable classifier)
4. `KYV-P03` or `KYV-P05` (deep dive)
5. `KYV-P12` (business-ready recommendations + policy templates)
6. `KYV-P04` (evolution/generate guardrails)
7. `KYV-P06` (executive trend)

---

## KYV-P01 - The Cluster Speaks

Objective:
- Show cluster-wide friction patterns by namespace and policy.

Prompt:
```text
Analyze Kyverno violations cluster-wide.
Group them by namespace and by policy.
Show:
- Total violations
- Top 3 most violated policies
- Which namespace concentrates more issues
```

Expected output:
- Cluster-wide summary with namespace and policy ranking.

Suggested narrative:
- "Violations are not noise. They are signals."

---

## KYV-P02 - Friction Threshold

Objective:
- Detect systemic friction when a policy crosses the threshold per namespace.

Prompt:
```text
For each namespace, count violations by policy.
If any policy exceeds 5 violations in the same namespace,
recommend whether:
- keep enforced,
- temporarily switch to audit,
- redesign the rule.

Do not apply changes.
Explain reasoning.
```

Expected output:
- Namespace/policy list with recommended decision and reasoning.

Suggested narrative:
- "We are not blaming workloads; we are detecting systemic friction."

---

## KYV-P03 - Improved Policy (Do Not Apply)

Objective:
- Propose policy redesign to reduce friction without losing control.

Prompt:
```text
Based on repeated violations in namespace {namespace},
propose an improved Kyverno policy that:
- maintains resource discipline,
- reduces friction for developers,
- avoids blocking deployments immediately.

Output the YAML but do not apply it.
```

Expected output:
- Proposed YAML (Audit/Mutate/contextual scope), not applied.

Suggested narrative:
- "The system does not self-correct; it self-improves with human control."

---

## KYV-P04 - Controlled Self-Healing (Generate Guardrails)

Objective:
- Propose an automated baseline for new namespaces.

Prompt:
```text
Detect namespaces missing baseline guardrails
(labels, hostPath restrictions, privileged restrictions).

Propose a generate policy so that
any new namespace automatically receives
a baseline set of restrictions.

Output the YAML only.
```

Expected output:
- `generate` policy YAML for namespace baseline guardrails.

Suggested narrative:
- "We move from static rules to behavior patterns."

---

## KYV-P05 - Production Drift

Objective:
- Evaluate risk from recurring violations in a critical namespace.

Prompt:
```text
Analyze violations in namespace {namespace}.
Explain what risk hostPath introduces.
Is this likely a one-time exception or systemic design issue?
Recommend action strategy.
```

Expected output:
- Risk assessment + classification (one-off exception vs structural issue).

---

## KYV-P06 - Trend (Executive Report)

Objective:
- Translate repeated patterns into governance health status.

Prompt:
```text
Assume the last 7 days show the same violation patterns.
Classify policies as:
- Healthy
- Friction-based
- Structural design issue

Provide a short governance report.
```

Expected output:
- Short report with policy classification and priorities.

---

## KYV-P11 - Non-Negotiable Policies (CIS/Security)

Objective:
- Separate non-negotiable controls from tunable controls and avoid unsafe recommendations.

Prompt:
```text
Analyze current Kyverno violations and classify each violated policy as:
- NON_NEGOTIABLE (CIS/security baseline)
- TUNABLE

Use this non-negotiable baseline:
- disallow-privileged-containers
- disallow-host-namespaces
- disallow-host-path
- require-run-as-non-root-user
- require-run-as-nonroot
- require-read-only-root-filesystem
- restrict-capabilities
- restrict-seccomp-strict
- require-network-policy
- disallow-latest-tag
- disallow-host-ports

If policy names differ, infer non-negotiable by keywords:
cis, pod-security, psa, security, seccomp, capabilit, privileged,
hostpath, host-namespace, non-root, read-only-root.

For each NON_NEGOTIABLE policy:
- provide count
- affected namespaces
- affected resource kinds
- remediation strategy that does NOT relax enforcement

For each TUNABLE policy:
- provide count
- tuning options (match/exclude granularity, better messages, temporary Audit with expiration date)

Do not apply changes.
```

Expected output:
- Classification table + prioritized remediation strategy.

Suggested narrative:
- "Security baselines are non-negotiable; friction is addressed through workload remediation and guided rollout."

---

## KYV-P12 - Business Recommendations + Policy Templates (Do Not Apply)

Objective:
- Produce actionable recommendations and Kyverno YAML templates with business placeholders.

Prompt:
```text
Using Kyverno violation data, produce:
1) Top friction policies with impact:
   - count
   - affected namespaces
   - affected resources
   - sample violation reason/message
2) Recommendations per policy:
   - if NON_NEGOTIABLE: do not relax; provide remediation path and rollout plan
   - if TUNABLE: propose safer tuning options
3) Suggested Kyverno policy templates (YAML, do not apply) with business placeholders:
   - disallow latest image tag
   - restrict privileged containers
   - require CPU/memory requests+limits
   - require ownership/cost labels
   - require network policy baseline

Use placeholders such as:
{business_unit}, {owner_team}, {environment}, {namespace}, {risk_tolerance}.

Output format:
- Section A: Friction summary
- Section B: Recommendations
- Section C: YAML templates only
```

Expected output:
- Concise report + reusable YAML templates customized with placeholders.

Suggested narrative:
- "From raw violations to reusable governance patterns aligned to business ownership."

---

## Additional Operational Prompts

### KYV-P07 - MCP Context
```text
List all available Kubernetes contexts from the Kyverno MCP server.
Return only a bullet list with context names.
```

### KYV-P08 - Switch Context
```text
Switch MCP execution context to "{context}".
Then confirm current context in one line.
```

### KYV-P09 - Deep Dive by Policy
```text
Analyze policy "{policy}" across all namespaces.
Return:
1) total hits
2) affected namespaces sorted desc
3) concentration insight (broad vs localized)
```

### KYV-P10 - Before/After Validation
```text
Compare current PolicyReport metrics with this previous snapshot:
{paste_snapshot_json}
Return:
1) delta total violations
2) delta top namespaces
3) delta top policies
4) one paragraph: did governance friction improve?
```

### KYV-P13 - Recommendations + Templates (English Variant)
```text
Analyze Kyverno violations and deliver:
1) Friction summary by policy and namespace.
2) Policy classification:
   - NON_NEGOTIABLE (CIS/security)
   - TUNABLE
3) Recommendations:
   - NON_NEGOTIABLE: do not relax enforcement, remediate at source.
   - TUNABLE: adjust match/exclude scope, improve messages, or use temporary Audit with expiration date.
4) Generate suggested YAML policies (do not apply) with business placeholders:
   - disallow latest tag
   - restrict privileged
   - require resources
   - require ownership/cost-center labels
   - network policy baseline per namespace

Use placeholders:
{business_unit}, {owner_team}, {environment}, {namespace}, {risk_tolerance}.
```
