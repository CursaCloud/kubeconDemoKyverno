#!/usr/bin/env bash
set -euo pipefail

kubectl delete -f policies/ 2>/dev/null || true

echo "Policies removed from ./policies"
