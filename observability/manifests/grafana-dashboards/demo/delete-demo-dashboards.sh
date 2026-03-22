#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl delete -f "${SCRIPT_DIR}/apps" --ignore-not-found
kubectl delete -f "${SCRIPT_DIR}/cluster" --ignore-not-found

echo "Demo dashboards deleted."
