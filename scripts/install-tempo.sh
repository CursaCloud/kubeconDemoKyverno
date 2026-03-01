#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

helm upgrade --install tempo grafana/tempo \
  -n "${OBS_NS}" \
  --values observability/helm-values/tempo-values.yaml

kubectl apply -f observability/manifests/grafana-datasources-tempo.yaml

cat <<MSG

Tempo installed in namespace '${OBS_NS}'.
MSG
