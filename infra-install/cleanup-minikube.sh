#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-kyverno-demo}"

minikube delete -p "${PROFILE}"

cat <<MSG

Minikube profile '${PROFILE}' deleted.
MSG
