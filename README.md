# kubeconDemoKyverno

Quick demo (Minikube + Kyverno + Policy Reporter UI)

Goal: create a real-world cluster with inconsistencies and use Kyverno + the UI to observe and improve governance over time.

Prerequisites
- `kubectl`, `minikube`, and `helm` installed and in your PATH.

Step 1: Create the cluster with Minikube
```bash
./infra-install/install-minikube.sh
```
Notes:
- Default profile is `kyverno-demo` (pass another name as the first arg).
- Tune resources with `MINIKUBE_CPUS` and `MINIKUBE_MEMORY`.

Examples:
```bash
./infra-install/install-minikube.sh demo-01
MINIKUBE_CPUS=6 MINIKUBE_MEMORY=8g ./infra-install/install-minikube.sh demo-02
```

Step 2: Install Kyverno + UI (Policy Reporter)
```bash
./scripts/install-kyverno.sh
```

Step 3: Create demo namespaces
```bash
./scripts/apply-namespaces.sh
```

Step 4: Apply base policies (cluster)
```bash
./scripts/apply-policies.sh
```

Step 5: Apply namespace policies
```bash
./scripts/apply-namespace-policies.sh
```

Step 6: Generate violations (for UI activity)
```bash
./scripts/apply-violations.sh
```

Step 7: Access the UI (2 options)

Option A: LoadBalancer with `minikube tunnel`
1) Switch the service to LoadBalancer (if the chart does not expose it by default):
```bash
kubectl -n policy-reporter patch svc policy-reporter-ui -p '{"spec":{"type":"LoadBalancer"}}'
```
2) In another terminal, create the tunnel:
```bash
minikube tunnel
```
3) Get the external IP and open it in a browser:
```bash
kubectl -n policy-reporter get svc policy-reporter-ui
```

Option B: Port-forward (quick and simple)
```bash
kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8080:8080
```
Then open `http://localhost:8080`.

Phase 2: Observability (OTEL)
```bash
./scripts/install-observability.sh
./scripts/verify-observability.sh
```

Access:
```bash
kubectl -n observability port-forward svc/kube-prom-stack-grafana 3000:80
kubectl -n observability port-forward svc/kube-prom-stack-prometheus 9090:9090
```

Phase 2 details:
- `observability/README.md`

Cleanup
```bash
./scripts/cleanup-violations.sh
./scripts/remove-policies.sh
./scripts/cleanup-kyverno.sh
./scripts/cleanup-observability.sh
./infra-install/cleanup-minikube.sh
```
