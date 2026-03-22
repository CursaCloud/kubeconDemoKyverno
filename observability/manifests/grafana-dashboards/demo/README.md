# Demo Dashboards

Recommended Grafana dashboards for the live demo.

## Suggested Order

1. `overview-apps.yaml`
2. `oom-restarts.yaml`
3. `memory-usage.yaml`
4. `app-payments-payments-api.yaml`
5. `app-observability-otel-collector.yaml`

## Why These Dashboards

- `overview-apps.yaml`
  - best opening view
  - shows which workloads deserve attention first

- `oom-restarts.yaml`
  - good operational signal
  - easy to explain live

- `memory-usage.yaml`
  - connects runtime behavior with resource governance
  - useful bridge into Kyverno policy discussion

- `app-payments-payments-api.yaml`
  - business workload example
  - good for showing memory, restarts, and usage vs limits

- `app-observability-otel-collector.yaml`
  - platform workload example
  - useful to show that governance friction is not limited to business apps

## Demo Narrative

Use this flow:

1. start with cluster-level visibility
2. identify a signal
3. move to memory and restart evidence
4. drill into a business app
5. contrast with a platform app

## Commands

Apply demo dashboards only:

```bash
./observability/manifests/grafana-dashboards/demo/apply-demo-dashboards.sh
```

Delete demo dashboards only:

```bash
./observability/manifests/grafana-dashboards/demo/delete-demo-dashboards.sh
```

## Organized Files

Cluster-focused dashboards:

- [overview-apps.yaml](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/observability/manifests/grafana-dashboards/demo/cluster/overview-apps.yaml)
- [oom-restarts.yaml](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/observability/manifests/grafana-dashboards/demo/cluster/oom-restarts.yaml)
- [memory-usage.yaml](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/observability/manifests/grafana-dashboards/demo/cluster/memory-usage.yaml)

App-focused dashboards:

- [app-payments-payments-api.yaml](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/observability/manifests/grafana-dashboards/demo/apps/app-payments-payments-api.yaml)
- [app-observability-otel-collector.yaml](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/observability/manifests/grafana-dashboards/demo/apps/app-observability-otel-collector.yaml)
