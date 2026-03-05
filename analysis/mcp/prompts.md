# Kyverno MCP Prompt Catalog

Official prompt catalog for governance analysis using `kyverno-mcp`.

## Conventions

- ID: `KYV-PXX`
- Language: English
- Focus: analysis and recommendation, no change execution (unless explicitly requested)
- Placeholders: `{namespace}`, `{policy}`, `{context}`, `{resource_kind}`, `{resource_name}`

## Recommended Demo Sequence

1. `KYV-P01` (cluster baseline)
2. `KYV-P02` (friction threshold)
3. `KYV-P03` or `KYV-P05` (deep dive)
4. `KYV-P04` (evolution/generate guardrails)
5. `KYV-P06` (executive trend)

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
