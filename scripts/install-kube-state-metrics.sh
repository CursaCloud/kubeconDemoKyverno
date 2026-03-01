#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

if helm -n "${OBS_NS}" status kube-prom-stack >/dev/null 2>&1; then
  cat <<MSG

kube-state-metrics is already provided by kube-prometheus-stack (release: kube-prom-stack).
MSG
  exit 0
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  -n "${OBS_NS}"

cat <<MSG

Standalone kube-state-metrics installed in namespace '${OBS_NS}'.
MSG
