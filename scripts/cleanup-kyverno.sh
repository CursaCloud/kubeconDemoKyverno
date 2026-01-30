#!/usr/bin/env bash
set -euo pipefail

KYVERNO_NS="${KYVERNO_NS:-kyverno}"
POLICY_REPORTER_NS="${POLICY_REPORTER_NS:-policy-reporter}"

helm uninstall kyverno -n "${KYVERNO_NS}" 2>/dev/null || true
helm uninstall policy-reporter -n "${POLICY_REPORTER_NS}" 2>/dev/null || true

kubectl delete namespace "${KYVERNO_NS}" 2>/dev/null || true
kubectl delete namespace "${POLICY_REPORTER_NS}" 2>/dev/null || true

cat <<MSG

Kyverno cleanup done.
Namespaces removed (if they existed):
- ${KYVERNO_NS}
- ${POLICY_REPORTER_NS}
MSG
