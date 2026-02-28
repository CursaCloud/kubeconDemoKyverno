# Phase 2: Observability (OTEL)

Goal: install a lightweight stack on Minikube to collect metrics and logs, and enable OTLP for apps that want to emit signals.

Components
- Prometheus + Grafana + kube-state-metrics (kube-prometheus-stack)
- Loki + Promtail (minimum viable logs)
- OTEL Collector (OTLP gateway + Prometheus exporter + Loki exporter)
- Tempo (optional)

Namespace
- `observability`

## Install (Phase 2)
```bash
./scripts/install-observability.sh
```

Optional (traces)
```bash
./scripts/install-tempo.sh
```
This also applies the Tempo datasource in Grafana.

## Mandatory verification
```bash
./scripts/verify-observability.sh
```

Ensure Ready:
- `kube-prom-stack-prometheus`
- `kube-prom-stack-grafana`
- `kube-prom-stack-kube-state-metrics`
- `otel-collector`
- `loki` and `promtail` (installed by default)
- `tempo` (if installed)

## Quick access
Grafana:
```bash
kubectl -n observability port-forward svc/kube-prom-stack-grafana 3000:80
```
Prometheus:
```bash
kubectl -n observability port-forward svc/kube-prom-stack-prometheus 9090:9090
```
Loki (basic test):
```bash
kubectl -n observability port-forward svc/loki 3100:3100
```

Default credentials:
- user: `admin`
- pass: `admin`

## OTLP endpoints
- gRPC: `otel-collector.observability.svc:4317`
- HTTP: `otel-collector.observability.svc:4318`

## PromQL ready to copy/paste (minimum 6)
1) OOMKilled (last 1h) per ns/pod/container (count of affected containers in window):
```
sum by (namespace,pod,container) (
  max_over_time(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[1h])
)
```
2) OOMKilled (last 7d) per ns/pod/container:
```
sum by (namespace,pod,container) (
  max_over_time(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[7d])
)
```
3) Restarts per container (last 1h):
```
sum by (namespace,pod,container) (
  increase(kube_pod_container_status_restarts_total[1h])
)
```
4) Current memory working set per pod/container:
```
sum by (namespace,pod,container) (
  container_memory_working_set_bytes{container!="", image!=""}
)
```
5) p95 memory working set per container (1h / 24h):
```
quantile_over_time(0.95, container_memory_working_set_bytes{container!="", image!=""}[1h])

quantile_over_time(0.95, container_memory_working_set_bytes{container!="", image!=""}[24h])
```
6) Declared requests/limits per container (memory):
```
# Requests
sum by (namespace,pod,container) (kube_pod_container_resource_requests{resource="memory"})

# Limits
sum by (namespace,pod,container) (kube_pod_container_resource_limits{resource="memory"})
```
7) Usage/limit ratio per container:
```
sum by (namespace,pod,container) (container_memory_working_set_bytes{container!="", image!=""})
/
sum by (namespace,pod,container) (kube_pod_container_resource_limits{resource="memory"})
```

## Dashboards included
- K8s: OOMKilled + Restarts
- K8s: Memory usage p95 vs limits
- K8s: Requests/Limits overview
- Overview: Top Apps
- App: <namespace/workload> (auto-generated)

## Auto-generated dashboards
Generate dashboards from repo manifests (Deployments/StatefulSets):
```bash
./scripts/generate-dashboards.sh
./scripts/apply-dashboards.sh
```

Variables used in per-app dashboards:
- `$namespace` (constant)
- `$workload` (constant)
- `$workload_kind` (constant)
- `$pod` (multi)
- `$container` (multi)

Limitations (Kyverno):
- No Kyverno metrics detected in Prometheus by default.
- The Overview dashboard includes a TODO panel. To enable: expose Kyverno metrics and add a ServiceMonitor to scrape them.

## OOM demo (optional)
```bash
./scripts/apply-oom-demo.sh
```
Cleanup:
```bash
./scripts/cleanup-oom-demo.sh
```

## Cleanup
```bash
./scripts/cleanup-observability.sh
```

## Phase 3 (MCP) - Notes (do not implement yet)
- OTLP gRPC: `otel-collector.observability.svc:4317`
- OTLP HTTP: `otel-collector.observability.svc:4318`
- Prometheus query: `kube-prom-stack-prometheus.observability.svc:9090`
- Grafana UI: `kube-prom-stack-grafana.observability.svc:80`
