#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

kubectl apply -f observability/manifests/grafana-dashboards/

cat <<MSG

Grafana dashboards applied in namespace '${OBS_NS}'.
MSG
