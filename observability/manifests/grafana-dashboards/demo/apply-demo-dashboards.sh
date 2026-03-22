#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "${SCRIPT_DIR}/cluster"
kubectl apply -f "${SCRIPT_DIR}/apps"

echo "Demo dashboards applied."
