#!/usr/bin/env bash
set -euo pipefail

DEMO_NS="${DEMO_NS:-apps}"

kubectl -n "${DEMO_NS}" delete deployment oom-demo --ignore-not-found

cat <<MSG

OOM demo removed from namespace '${DEMO_NS}'.
MSG
