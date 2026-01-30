#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f violations/

echo "Violation workloads applied from ./violations"
