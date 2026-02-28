#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

helm -n "${OBS_NS}" uninstall promtail >/dev/null 2>&1 || true
helm -n "${OBS_NS}" uninstall loki >/dev/null 2>&1 || true
helm -n "${OBS_NS}" uninstall tempo >/dev/null 2>&1 || true
helm -n "${OBS_NS}" uninstall kube-prom-stack >/dev/null 2>&1 || true
helm -n "${OBS_NS}" uninstall grafana >/dev/null 2>&1 || true
helm -n "${OBS_NS}" uninstall kube-state-metrics >/dev/null 2>&1 || true

kubectl delete -f observability/manifests/otel-collector-deploy.yaml >/dev/null 2>&1 || true
kubectl delete -f observability/manifests/otel-collector-config.yaml >/dev/null 2>&1 || true
kubectl delete -f observability/manifests/grafana-datasources.yaml >/dev/null 2>&1 || true
kubectl delete -f observability/manifests/grafana-datasources-tempo.yaml >/dev/null 2>&1 || true
kubectl delete -f observability/manifests/grafana-dashboards/ >/dev/null 2>&1 || true

cat <<MSG

Observability stack removed from namespace '${OBS_NS}'.
MSG
