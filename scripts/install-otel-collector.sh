#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

kubectl create namespace "${OBS_NS}" 2>/dev/null || true

kubectl apply -f observability/manifests/otel-collector-config.yaml
kubectl apply -f observability/manifests/otel-collector-deploy.yaml

cat <<MSG

OTEL Collector installed in namespace '${OBS_NS}'.
OTLP endpoints:
  - gRPC:  otel-collector.${OBS_NS}.svc:4317
  - HTTP:  otel-collector.${OBS_NS}.svc:4318
MSG
