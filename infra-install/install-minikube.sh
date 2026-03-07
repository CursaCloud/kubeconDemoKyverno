#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-kyverno-demo}"
CPUS="${MINIKUBE_CPUS:-4}"
MEMORY="${MINIKUBE_MEMORY:-6g}"

minikube start -p "${PROFILE}" --cpus="${CPUS}" --memory="${MEMORY}"

cat <<MSG

Minikube profile '${PROFILE}' is ready.
To use it:
  minikube profile ${PROFILE}
  kubectl config use-context ${PROFILE}
MSG
