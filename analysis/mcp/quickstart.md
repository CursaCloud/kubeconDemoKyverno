# Kyverno MCP Quickstart (5 Commands)

## 1) Start the correct Minikube profile

```bash
minikube -p kyverno-demo start
```

## 2) Register the MCP server in Codex (stdio)

```bash
codex mcp remove kyverno-demo 2>/dev/null || true
codex mcp add kyverno-demo --env KUBECONFIG=$HOME/.kube/minikube-config -- /opt/homebrew/bin/kyverno-mcp
```

## 3) Verify the registration

```bash
codex mcp get kyverno-demo
```

Expected:
- `command: /opt/homebrew/bin/kyverno-mcp`
- `args: -`
- `env: KUBECONFIG=*****`

## 4) Open Codex in this repository

```bash
cd /Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno
codex
```

## 5) Run a validation prompt

```text
Use kyverno-mcp to list the available Kubernetes contexts, then switch to the kyverno-demo context.
```

## Recommended analysis prompt

```text
Use kyverno-mcp to analyze policy violations in the observability namespace.
I want:
1) total number of violations
2) top 5 policies by count
3) a brief conclusion (3-4 lines) about the main operational friction
Do not apply any changes.
```

## Quick troubleshooting

If you see:
- `MCP startup failed: ... initialize response`

Re-register the MCP server:

```bash
codex mcp remove kyverno-demo
codex mcp add kyverno-demo --env KUBECONFIG=$HOME/.kube/minikube-config -- /opt/homebrew/bin/kyverno-mcp
```

Important:
- Do not use `--context` when starting `kyverno-mcp`.
- Change context using the `switch_context` tool.
