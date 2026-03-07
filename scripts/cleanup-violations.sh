#!/usr/bin/env bash
set -euo pipefail

kubectl delete -f violations/ 2>/dev/null || true

echo "Violation workloads removed from ./violations"
