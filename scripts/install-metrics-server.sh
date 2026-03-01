#!/usr/bin/env bash
set -euo pipefail

MANIFEST_URL="${METRICS_SERVER_MANIFEST_URL:-https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml}"

ensure_arg() {
  local arg="$1"
  local current_args

  current_args="$(kubectl -n kube-system get deployment metrics-server -o jsonpath='{.spec.template.spec.containers[0].args[*]}' 2>/dev/null || true)"
  if [[ "${current_args}" == *"${arg}"* ]]; then
    return 0
  fi

  kubectl -n kube-system patch deployment metrics-server --type='json' \
    -p="[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/args/-\",\"value\":\"${arg}\"}]" >/dev/null
}

kubectl apply -f "${MANIFEST_URL}"

# Minikube commonly requires these settings to scrape kubelet metrics reliably.
ensure_arg "--kubelet-insecure-tls"
ensure_arg "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"

kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s

cat <<MSG

metrics-server installed and ready.
Quick checks:
  kubectl get apiservice v1beta1.metrics.k8s.io
  kubectl top nodes
MSG
