#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
  -n "${OBS_NS}" \
  --values observability/helm-values/kube-prometheus-stack-values.yaml

cat <<MSG

Prometheus stack installed in namespace '${OBS_NS}'.
MSG
