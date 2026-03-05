# MCP Analysis - Kyverno MCP

Use `kyverno-mcp` to analyze governance and violations from an MCP client.

## Prerequisites

- `kyverno-mcp` installed (detected at `/opt/homebrew/bin/kyverno-mcp`)
- Minikube profile `kyverno-demo` running
- Valid kubeconfig: `~/.kube/minikube-config`

## Quick Start

From the repo root:

```bash
./analysis/mcp/run-kyverno-mcp.sh
```

Optional with explicit kubeconfig:

```bash
KUBECONFIG=~/.kube/minikube-config ./analysis/mcp/run-kyverno-mcp.sh
```

## Copy/Paste Configuration for MCP Clients

```json
{
  "mcpServers": {
    "kyverno-demo": {
      "command": "kyverno-mcp",
      "args": [],
      "env": {
        "KUBECONFIG": "/Users/oscar.castillo/.kube/minikube-config"
      }
    }
  }
}
```

Important note:
- Do not pass `--context` as a startup argument to the binary.
- Change context using the MCP tool `switch_context`.

## HTTP Variant (if your client does not support stdio)

1. Start the HTTP server:
   - `./analysis/mcp/run-kyverno-mcp.sh`
2. Configure the MCP URL:
   - `http://127.0.0.1:8088`

JSON example (clients that use MCP URL):

```json
{
  "mcpServers": {
    "kyverno-demo": {
      "url": "http://127.0.0.1:8088"
    }
  }
}
```

## What the MCP Server Exposes

According to `kyverno-mcp --help`, the server exposes:

- `list_contexts`
- `switch_context` (requires `--context`)
- `apply_policies`
- `help`
- `show_violations`

## Codex CLI Configuration (Validated)

Register MCP server:

```bash
codex mcp remove kyverno-demo 2>/dev/null || true
codex mcp add kyverno-demo --env KUBECONFIG=$HOME/.kube/minikube-config -- /opt/homebrew/bin/kyverno-mcp
```

Verify:

```bash
codex mcp get kyverno-demo
```

Expected result:
- `command: /opt/homebrew/bin/kyverno-mcp`
- `args: -` (no arguments)
- `env: KUBECONFIG=*****`

## Suggested Demo Flow

1. `list_contexts` to validate available clusters.
2. `switch_context` to `kyverno-demo` if it is not active.
3. `show_violations` on namespaces or resources with highest friction (`observability`, `kube-system`, `kyverno`).
4. `apply_policies` to demonstrate tuning/remediation and revalidate violations.

## Troubleshooting

Error:
- `MCP startup failed: ... initialize response`

Common cause:
- The server was registered with invalid args (for example: `--context kyverno-demo`).

Quick fix:

```bash
codex mcp remove kyverno-demo
codex mcp add kyverno-demo --env KUBECONFIG=$HOME/.kube/minikube-config -- /opt/homebrew/bin/kyverno-mcp
codex mcp get kyverno-demo
```

If it persists:
1. Restart the `codex` process.
2. Verify Minikube profile `kyverno-demo` is `Running`.
3. Run `kyverno-mcp --help` to confirm the binary responds.
