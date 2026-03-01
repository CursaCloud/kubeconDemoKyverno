#!/usr/bin/env bash
set -euo pipefail

OBS_NS="${OBS_NS:-observability}"

printf "\nPods in namespace '%s':\n" "${OBS_NS}"
kubectl -n "${OBS_NS}" get pods -o wide

printf "\nServices in namespace '%s':\n" "${OBS_NS}"
kubectl -n "${OBS_NS}" get svc

cat <<MSG

Required components (check Ready):
  - Prometheus (kube-prom-stack-prometheus)
  - Grafana (kube-prom-stack-grafana)
  - kube-state-metrics (kube-prom-stack-kube-state-metrics)
  - OTEL Collector (otel-collector)
  - Loki (loki) + Promtail (promtail) [optional but installed by default]
  - Tempo (tempo) [optional]

Access:
  Grafana:    kubectl -n ${OBS_NS} port-forward svc/kube-prom-stack-grafana 3000:80
  Prometheus: kubectl -n ${OBS_NS} port-forward svc/kube-prom-stack-prometheus 9090:9090
  Loki test:  kubectl -n ${OBS_NS} port-forward svc/loki 3100:3100

OTLP endpoints:
  - gRPC:  otel-collector.${OBS_NS}.svc:4317
  - HTTP:  otel-collector.${OBS_NS}.svc:4318
MSG
