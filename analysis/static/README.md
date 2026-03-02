# Static Analysis - Kyverno PolicyReports

Este modulo forma parte del demo y sirve para medir friccion de politicas Kyverno en el cluster.

## Que hace

El script [`main.py`](/Users/oscar.castillo/Documents/Personal/KubeCon_2026_KyvernoCon/Demo/kubeconDemoKyverno/analysis/static/main.py):

1. Ejecuta `kubectl get policyreports -A -o json`.
2. Agrupa resultados por `namespace` y `policy`.
3. Cuenta violaciones por policy.
4. Marca `Friction Detected` si una policy supera el umbral definido en `THRESHOLD` (actual: `5`).

## Prerequisitos

- Python 3
- `kubectl` instalado
- Acceso al cluster del demo con:
  - `KUBECONFIG=~/.kube/minikube-config`

## Uso

Desde la raiz del repo:

```bash
KUBECONFIG=~/.kube/minikube-config python3 analysis/static/main.py
```

## Ejemplo de interpretacion

Si la salida muestra:

- `Namespace: observability`
- `disallow-latest-tag: 26 -> Friction Detected`

significa que en `observability` esa policy esta bloqueando/advirtiendo con alta frecuencia, por encima del umbral de friccion definido para el demo.

## Nota para la demo

Este reporte es ideal para abrir la narrativa de "donde duele la adopcion de politicas" antes de mostrar remediacion, excepciones o ajustes de enforcement.
