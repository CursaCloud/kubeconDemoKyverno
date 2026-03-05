#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
CONTEXT="${K8S_CONTEXT:-kyverno-demo}"
HTTP_ADDR="${MCP_HTTP_ADDR:-127.0.0.1:8088}"

echo "Starting kyverno-mcp"
echo "  kubeconfig: ${KUBECONFIG_PATH}"
echo "  context:    ${CONTEXT}"
echo "  http addr:  ${HTTP_ADDR}"

exec kyverno-mcp \
  --kubeconfig "${KUBECONFIG_PATH}" \
  --context "${CONTEXT}" \
  --http \
  --http-addr "${HTTP_ADDR}"
