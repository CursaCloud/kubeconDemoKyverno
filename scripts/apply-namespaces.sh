#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f namespaces/

echo "Namespaces applied from ./namespaces"
