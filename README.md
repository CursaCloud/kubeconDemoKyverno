# kubeconDemoKyverno

End-to-end Kyverno project on Minikube with three main parts:

- cluster bootstrap and base component installation,
- policies and workloads designed to generate realistic governance friction,
- analysis and observability to explain that friction.

## Repository Contents

### Infrastructure and bootstrap

- `infra-install/`
  - create and clean up the Minikube profile.
- `scripts/`
  - install Kyverno, Policy Reporter, and the observability stack,
  - apply and clean up namespaces, policies, and violation workloads.

### Policies and violations

- `namespaces/`
  - working namespaces: `payments`, `orders`, `marketing`, `data-platform`, `observability`.
- `policies/`
  - base Kyverno policies,
  - namespace-specific policies under `policies/namespaces/`.
- `violations/`
  - intentionally misconfigured manifests used to generate PolicyReports.

### Observability

- `observability/`
  - Helm values for Prometheus, Loki, Promtail, and Tempo,
  - manifests for the OTEL Collector, Grafana datasources, and dashboards,
  - component-specific documentation in `observability/README.md`.

### Analysis

- `analysis/static/`
  - Python analyzer that reads `PolicyReport` objects from the cluster and generates recommendations and YAML templates.
- `analysis/governance-ai/`
  - documentation and agent workflow for analysis, proposal authoring, and review,
  - prompt catalogs and role guidance.

## Prerequisites

- `kubectl`
- `minikube`
- `helm`
- `python3`

Optional:

- `kyverno` CLI for manual policy simulation
- an MCP environment if you plan to use the workflow documented in `analysis/governance-ai/`

## Quick Start

The scripts assume that `kubectl` points to the correct Minikube context.

1. Create the cluster:

```bash
./infra-install/install-minikube.sh
kubectl config use-context kyverno-demo
```

2. Install Kyverno and Policy Reporter:

```bash
./scripts/install-kyverno.sh
```

3. Create namespaces:

```bash
./scripts/apply-namespaces.sh
```

4. Apply policies:

```bash
./scripts/apply-policies.sh
./scripts/apply-namespace-policies.sh
```

5. Apply workloads that generate violations:

```bash
./scripts/apply-violations.sh
```

## Policy Visibility

Policy Reporter UI:

```bash
kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8080:8080
```

Open `http://localhost:8080`.

## Static Analysis

The analyzer reads `PolicyReport` data and summarizes:

- violations by namespace and policy,
- policies with the most friction,
- non-negotiable controls,
- actionable recommendations,
- automatically generated Kyverno policy templates.

Run it from the repository root:

```bash
python3 analysis/static/main.py
```

Generated output:

- console summary of the analysis,
- YAML files under `analysis/static/generated-policies/`.

Note: run it from the repo root so the generated output lands in that path instead of a duplicated nested directory.

## Governance AI

The `analysis/governance-ai/` directory documents a workflow separate from the static analyzer:

1. an analyst interprets cluster signals,
2. an author proposes Kyverno YAML,
3. a reviewer validates scope and safety,
4. a human decides whether to promote changes.

Main entry points:

- `analysis/governance-ai/README.md`
- `analysis/governance-ai/prompts/catalog.md`

## Observability

Install:

```bash
./scripts/install-observability.sh
./scripts/verify-observability.sh
```

Quick access:

```bash
kubectl -n observability port-forward svc/kube-prom-stack-grafana 3000:80
kubectl -n observability port-forward svc/kube-prom-stack-prometheus 9090:9090
```

Default Grafana credentials:

- user: `admin`
- password: `admin`

Additional dashboards:

```bash
./scripts/generate-dashboards.sh
./scripts/apply-dashboards.sh
```

See `observability/README.md` for more detail.

## Cleanup

Remove violation workloads:

```bash
./scripts/cleanup-violations.sh
```

Remove policies:

```bash
./scripts/remove-policies.sh
```

Remove Kyverno and Policy Reporter:

```bash
./scripts/cleanup-kyverno.sh
```

Remove observability components:

```bash
./scripts/cleanup-observability.sh
```

Delete the Minikube profile:

```bash
./infra-install/cleanup-minikube.sh
```

## Maintenance Notes

- `README.md` now reflects the actual repository layout.
- The MCP flow previously referenced does not live under `analysis/mcp/`; the current documentation is under `analysis/governance-ai/`.
- Some auxiliary files still use historical filenames such as `analysis/governance-ai/README-demo.md`, `governance-ai-demo-notes.txt`, and the `observability/manifests/grafana-dashboards/demo/` directory, but their content has been normalized to project-oriented wording.
- There is also untracked content under `analysis/static/analysis/`. I did not modify it.
