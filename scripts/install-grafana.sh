#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

if helm -n "${OBS_NS}" status kube-prom-stack >/dev/null 2>&1; then
  cat <<MSG

Grafana is already provided by kube-prometheus-stack (release: kube-prom-stack).
Use port-forward:
  kubectl -n ${OBS_NS} port-forward svc/kube-prom-stack-grafana 3000:80
MSG
  exit 0
fi

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

helm upgrade --install grafana grafana/grafana \
  -n "${OBS_NS}" \
  --set adminUser=admin \
  --set adminPassword=admin

cat <<MSG

Standalone Grafana installed in namespace '${OBS_NS}'.
MSG
