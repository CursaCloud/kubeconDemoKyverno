# Static Analysis - Kyverno PolicyReports

This module is part of the demo and is used to measure Kyverno policy friction in the cluster.

## What It Does

The script [`main.py`](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/analysis/static/main.py):

1. Runs `kubectl get policyreports -A -o json`.
2. Groups results by `namespace` and `policy`.
3. Counts violations per policy.
4. Marks `Friction Detected` if a policy exceeds the threshold defined in `THRESHOLD` (current: `5`).

## Prerequisites

- Python 3
- `kubectl` installed
- Access to the demo cluster with:
  - `KUBECONFIG=~/.kube/minikube-config`

## Usage

From the repo root:

```bash
KUBECONFIG=~/.kube/minikube-config python3 analysis/static/main.py
```

## Interpretation Example

If the output shows:

- `Namespace: observability`
- `disallow-latest-tag: 26 -> Friction Detected`

it means that in `observability` this policy is blocking/warning at high frequency, above the friction threshold defined for the demo.

## Demo Note

This report is ideal to start the narrative of "where policy adoption hurts" before showing remediation, exceptions, or enforcement tuning.
