#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f policies/namespaces/

echo "Namespace policies applied from ./policies/namespaces"
