# kubeconDemoKyverno

Demo to analyze Kyverno policy friction using Kubernetes `PolicyReport`.

## Structure

- `analysis/static/main.py`: script that queries `policyreports` and summarizes violations by namespace/policy.
- `analysis/static/README.md`: specific usage guide for static analysis.

## Manual Analysis Objective

This analysis is intended to quickly answer:

- which namespaces have the highest policy-driven operational friction
- which policies concentrate the most violations
- where to prioritize enforcement tuning, remediation, or exceptions

## Demo Flow (Phase 3)

1. Connect to the local demo cluster (Minikube) using:
   - `KUBECONFIG=~/.kube/minikube-config`
2. Run the analyzer:
   - `python3 analysis/static/main.py`
3. Present the result by namespace:
   - total violations
   - highest-friction policies
   - alert when a policy exceeds the threshold (`THRESHOLD=5`, rule `count > 5`)

## Recommended Execution

```bash
KUBECONFIG=~/.kube/minikube-config python3 analysis/static/main.py
```

## Expected Result

The script prints a summary like:

- `Namespace: observability`
- `Total Violations: 137`
- Policies with high counts marked as `Friction Detected`

This makes it easy to explain which namespaces and policies are generating the most operational friction in the cluster.

## Current Scope

- counting by namespace/policy based on `PolicyReport`
- console output for manual review (no CSV/JSON export)
- fixed in-code threshold (`THRESHOLD = 5`)
- no severity/result differentiation (`fail`, `warn`, `pass`)
