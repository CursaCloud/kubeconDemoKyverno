#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f policies/

echo "Policies applied from ./policies"
