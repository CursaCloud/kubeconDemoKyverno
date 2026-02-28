#!/usr/bin/env bash
set -euo pipefail

DEMO_NS="${DEMO_NS:-apps}"

kubectl create namespace "${DEMO_NS}" 2>/dev/null || true

cat <<'YAML' | kubectl apply -n "${DEMO_NS}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oom-demo
  labels:
    app: oom-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oom-demo
  template:
    metadata:
      labels:
        app: oom-demo
    spec:
      containers:
        - name: stress
          image: polinux/stress
          args: ["--vm", "1", "--vm-bytes", "256M", "--vm-hang", "1"]
          resources:
            requests:
              memory: "32Mi"
              cpu: "50m"
            limits:
              memory: "64Mi"
              cpu: "200m"
YAML

cat <<MSG

OOM demo applied in namespace '${DEMO_NS}'.
Check events with:
  kubectl -n ${DEMO_NS} describe pod -l app=oom-demo
MSG
