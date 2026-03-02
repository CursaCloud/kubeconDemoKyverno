# kubeconDemoKyverno

Demo para analizar friccion de politicas Kyverno usando `PolicyReport` de Kubernetes.

## Estructura

- `analysis/static/main.py`: script que consulta `policyreports` y resume violaciones por namespace/policy.
- `analysis/static/README.md`: guia especifica de uso del analisis estatico.

## Flujo del demo (fase3)

1. Conectarte al cluster local de demo (Minikube) usando:
   - `KUBECONFIG=~/.kube/minikube-config`
2. Ejecutar el analizador:
   - `python3 analysis/static/main.py`
3. Mostrar el resultado por namespace:
   - total de violaciones
   - politicas con mayor friccion
   - alerta cuando una policy supera el umbral (`THRESHOLD=5`)

## Ejecucion recomendada

```bash
KUBECONFIG=~/.kube/minikube-config python3 analysis/static/main.py
```

## Resultado esperado

El script imprime un resumen tipo:

- `Namespace: observability`
- `Total Violations: 137`
- Policies con conteo alto marcadas como `Friction Detected`

Esto permite explicar rapidamente que namespaces y politicas estan generando mas friccion operativa en el cluster.
