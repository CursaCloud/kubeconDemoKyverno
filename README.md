# kubeconDemoKyverno

End-to-end demo for Kyverno governance in a real Minikube environment:
- deploy a cluster with intentionally inconsistent workloads,
- observe policy friction with Policy Reporter UI and MCP analysis,
- generate actionable recommendations and reusable policy templates,
- enforce non-negotiable CIS/security controls.

## Demo Scope

This repository covers:
- Cluster bootstrap and teardown.
- Kyverno installation and policy rollout.
- Violation generation for realistic governance friction.
- UI-based and CLI-based analysis.
- Static analysis (`analysis/static/main.py`) with:
  - friction detection by namespace/policy,
  - non-negotiable policy classification,
  - recommendations,
  - suggested Kyverno YAML templates with business placeholders,
  - file generation to `analysis/static/generated-policies/`.
- MCP analysis prompt catalog (`analysis/mcp/prompts.md`) with:
  - non-negotiable vs tunable policy classification,
  - recommendation prompts,
  - policy-template generation prompts.

## Prerequisites

- `kubectl`, `minikube`, `helm`, `python3` in `PATH`.
- Optional (for MCP flow): `kyverno-mcp` installed.

## Environment

Use the demo kubeconfig when running commands:

```bash
export KUBECONFIG=~/.kube/minikube-config
```

## Setup Flow (Cluster + Policies + Violations)

1. Create the cluster:
```bash
./infra-install/install-minikube.sh
```

2. Install metrics server:
```bash
./scripts/install-metrics-server.sh
```

3. Install Kyverno + Policy Reporter:
```bash
./scripts/install-kyverno.sh
```

4. Create demo namespaces:
```bash
./scripts/apply-namespaces.sh
```

5. Apply cluster and namespace policies:
```bash
./scripts/apply-policies.sh
./scripts/apply-namespace-policies.sh
```

6. Generate violations:
```bash
./scripts/apply-violations.sh
```

## Access Policy Reporter UI

Option A (LoadBalancer + tunnel):
```bash
kubectl -n policy-reporter patch svc policy-reporter-ui -p '{"spec":{"type":"LoadBalancer"}}'
minikube tunnel
kubectl -n policy-reporter get svc policy-reporter-ui
```

Option B (port-forward):
```bash
kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8080:8080
```
Open `http://localhost:8080`.

## Static Analysis Flow

Run:

```bash
python3 analysis/static/main.py
```

What it outputs:
- violation summary by namespace and policy,
- top friction policies,
- non-negotiable (CIS/security) policy section,
- actionable recommendations,
- suggested policy templates with placeholders,
- generated YAML file list.

Generated files:
- `analysis/static/generated-policies/*.yaml`

## MCP Analysis Flow

Prompt catalog:
- `analysis/mcp/prompts.md`

Recommended prompts for this demo:
1. `KYV-P01` baseline.
2. `KYV-P02` friction threshold.
3. `KYV-P11` non-negotiable classifier.
4. `KYV-P12` recommendations + business-ready policy templates.
5. `KYV-P06` executive trend framing.

## Observability (Optional)

```bash
./scripts/install-observability.sh
./scripts/verify-observability.sh
```

Access:
```bash
kubectl -n observability port-forward svc/kube-prom-stack-grafana 3000:80
kubectl -n observability port-forward svc/kube-prom-stack-prometheus 9090:9090
```

Details:
- `observability/README.md`

## Cleanup

```bash
./scripts/cleanup-violations.sh
./scripts/remove-policies.sh
./scripts/cleanup-kyverno.sh
./scripts/cleanup-observability.sh
./infra-install/cleanup-minikube.sh
```
