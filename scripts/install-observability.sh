#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

"${SCRIPT_DIR}/install-prometheus.sh"
"${SCRIPT_DIR}/install-loki.sh"
"${SCRIPT_DIR}/install-otel-collector.sh"

kubectl apply -f observability/manifests/grafana-datasources.yaml
kubectl apply -f observability/manifests/grafana-dashboards/

cat <<MSG

Observability stack installed in namespace '${OBS_NS}'.

Next:
  ./scripts/verify-observability.sh
  kubectl -n ${OBS_NS} port-forward svc/kube-prom-stack-grafana 3000:80
  kubectl -n ${OBS_NS} port-forward svc/kube-prom-stack-prometheus 9090:9090
MSG
