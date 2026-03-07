#!/usr/bin/env bash
set -euo pipefail

KYVERNO_NS="${KYVERNO_NS:-kyverno}"
POLICY_REPORTER_NS="${POLICY_REPORTER_NS:-policy-reporter}"

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo add policy-reporter https://kyverno.github.io/policy-reporter
helm repo update

kubectl create namespace "${KYVERNO_NS}" 2>/dev/null || true
helm upgrade --install kyverno kyverno/kyverno -n "${KYVERNO_NS}"

kubectl create namespace "${POLICY_REPORTER_NS}" 2>/dev/null || true
helm upgrade --install policy-reporter policy-reporter/policy-reporter \
  -n "${POLICY_REPORTER_NS}" \
  --create-namespace \
  --set ui.enabled=true \
  --set plugin.kyverno.enabled=true

cat <<MSG

Kyverno installed in namespace '${KYVERNO_NS}'.
Policy Reporter UI installed in namespace '${POLICY_REPORTER_NS}'.

Next:
  kubectl -n ${POLICY_REPORTER_NS} port-forward svc/policy-reporter-ui 8080:8080
MSG
