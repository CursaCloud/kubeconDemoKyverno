#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

helm upgrade --install loki grafana/loki \
  -n "${OBS_NS}" \
  --values observability/helm-values/loki-values.yaml

helm upgrade --install promtail grafana/promtail \
  -n "${OBS_NS}" \
  --values observability/helm-values/promtail-values.yaml

cat <<MSG

Loki + Promtail installed in namespace '${OBS_NS}'.
MSG
