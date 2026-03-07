#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/observability/manifests/grafana-dashboards"

mkdir -p "${OUT_DIR}"

python3 - <<'PY'
import json
import os
import re
from pathlib import Path
from textwrap import indent

root = Path(os.getcwd()).resolve()
out_dir = root / "observability" / "manifests" / "grafana-dashboards"
out_dir.mkdir(parents=True, exist_ok=True)

yaml_files = [p for p in root.rglob("*.yml")] + [p for p in root.rglob("*.yaml")]
# Skip generated dashboards to avoid feedback loops
yaml_files = [p for p in yaml_files if "observability/manifests/grafana-dashboards" not in str(p)]

try:
    import yaml  # type: ignore
except Exception:
    yaml = None

def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9-]+", "-", s).strip("-").lower()
    return s or "unknown"

def truncate_name(name: str, max_len: int = 50) -> str:
    return name if len(name) <= max_len else name[:max_len].rstrip("-")

workloads = []

def parse_docs_with_pyyaml(path: Path):
    with path.open("r", encoding="utf-8") as f:
        docs = list(yaml.safe_load_all(f))
    return docs

def fallback_parse(path: Path):
    content = path.read_text(encoding="utf-8")
    docs = re.split(r"^---\s*$", content, flags=re.M)
    parsed = []
    for doc in docs:
        if not doc.strip():
            continue
        kind = None
        name = None
        namespace = None
        labels = {}
        containers = []
        in_labels = False
        labels_indent = None
        in_containers = False
        containers_indent = None
        container_item_indent = None
        in_metadata = False
        metadata_indent = None

        def indent_level(line: str) -> int:
            return len(line) - len(line.lstrip(" "))
        for line in doc.splitlines():
            if re.match(r"^kind:\s*(Deployment|StatefulSet)\s*$", line):
                kind = line.split(":", 1)[1].strip()
            if re.match(r"^\s*metadata:\s*$", line):
                in_metadata = True
                metadata_indent = indent_level(line)
                continue
            if in_metadata:
                if indent_level(line) <= (metadata_indent or 0) and line.strip():
                    in_metadata = False
                else:
                    if re.match(r"^\s*name:\s*", line) and name is None:
                        name = line.split(":", 1)[1].strip()
                    if re.match(r"^\s*namespace:\s*", line) and namespace is None:
                        namespace = line.split(":", 1)[1].strip()
            if re.match(r"^\s*labels:\s*$", line):
                in_labels = True
                labels_indent = indent_level(line)
                continue
            if in_labels:
                if indent_level(line) <= (labels_indent or 0) and line.strip():
                    in_labels = False
                elif re.match(r"^\s{2,}\S+:\s*\S+", line):
                    k, v = line.strip().split(":", 1)
                    labels[k.strip()] = v.strip().strip('"')
            if re.match(r"^\s*containers:\s*$", line):
                in_containers = True
                containers_indent = indent_level(line)
                container_item_indent = None
                continue
            if in_containers:
                if indent_level(line) <= (containers_indent or 0) and line.strip():
                    in_containers = False
                else:
                    m = re.match(r"^\s*-\s*name:\s*(\S+)", line)
                    if m:
                        if container_item_indent is None:
                            container_item_indent = indent_level(line)
                        if indent_level(line) == container_item_indent:
                            containers.append(m.group(1))
        if kind:
            parsed.append({
                "kind": kind,
                "metadata": {"name": name, "namespace": namespace, "labels": labels},
                "spec": {"template": {"spec": {"containers": [{"name": c} for c in containers]}}},
            })
    return parsed

for path in yaml_files:
    docs = []
    if yaml is not None:
        try:
            docs = parse_docs_with_pyyaml(path)
        except Exception:
            docs = fallback_parse(path)
    else:
        docs = fallback_parse(path)

    for doc in docs:
        if not isinstance(doc, dict):
            continue
        kind = doc.get("kind")
        if kind not in {"Deployment", "StatefulSet"}:
            continue
        metadata = doc.get("metadata", {}) or {}
        spec = doc.get("spec", {}) or {}
        name = metadata.get("name") or "unknown"
        namespace = metadata.get("namespace") or "default"
        labels = {}
        labels.update(metadata.get("labels", {}) or {})
        tmpl_labels = (((spec.get("template") or {}).get("metadata") or {}).get("labels") or {})
        labels.update(tmpl_labels)
        app_label = labels.get("app.kubernetes.io/name") or labels.get("app") or name
        containers = []
        tmpl_spec = ((spec.get("template") or {}).get("spec") or {})
        for c in tmpl_spec.get("containers", []) or []:
            cname = c.get("name")
            if cname:
                containers.append(cname)
        workloads.append({
            "kind": kind,
            "name": name,
            "namespace": namespace,
            "app": app_label,
            "containers": containers,
            "source": str(path.relative_to(root)),
        })

# Deduplicate by namespace+kind+name
seen = set()
unique = []
for w in workloads:
    key = (w["namespace"], w["kind"], w["name"])
    if key in seen:
        continue
    seen.add(key)
    unique.append(w)

workloads = sorted(unique, key=lambda w: (w["namespace"], w["kind"], w["name"]))

print("Detected workloads:")
for w in workloads:
    c = ",".join(w["containers"]) if w["containers"] else "(no containers found)"
    print(f"- {w['namespace']}/{w['kind']}/{w['name']} app={w['app']} containers={c} source={w['source']}")

# Dashboard templates

def dashboard_common(title, uid, tags=None):
    return {
        "uid": uid,
        "title": title,
        "timezone": "browser",
        "schemaVersion": 38,
        "version": 1,
        "refresh": "30s",
        "tags": tags or ["kubernetes", "auto"],
    }


def app_dashboard(w):
    ns = w["namespace"]
    name = w["name"]
    kind = w["kind"]
    app = w["app"]
    uid = f"app-{slugify(ns)}-{slugify(name)}"

    dash = dashboard_common(f"App: {app} ({ns}/{name})", uid, ["kubernetes", "app", ns])
    dash["templating"] = {
        "list": [
            {
                "name": "namespace",
                "type": "constant",
                "hide": 2,
                "query": ns,
                "label": "namespace",
            },
            {
                "name": "workload",
                "type": "constant",
                "hide": 2,
                "query": name,
                "label": "workload",
            },
            {
                "name": "workload_kind",
                "type": "constant",
                "hide": 2,
                "query": kind,
                "label": "workload_kind",
            },
            {
                "name": "pod",
                "type": "query",
                "datasource": "Prometheus",
                "query": "label_values(kube_pod_owner{namespace=\"$namespace\", owner_kind=\"$workload_kind\", owner_name=\"$workload\"}, pod)",
                "refresh": 1,
                "includeAll": True,
                "multi": True,
            },
            {
                "name": "container",
                "type": "query",
                "datasource": "Prometheus",
                "query": "label_values(kube_pod_container_info{namespace=\"$namespace\", pod=~\"$pod\"}, container)",
                "refresh": 1,
                "includeAll": True,
                "multi": True,
            },
        ]
    }

    panels = []
    y = 0

    panels.append({
        "type": "timeseries",
        "title": "Replicas desired vs available",
        "gridPos": {"x": 0, "y": y, "w": 24, "h": 8},
        "targets": [
            {
                "expr": "kube_deployment_spec_replicas{namespace=\"$namespace\", deployment=\"$workload\"} or kube_statefulset_replicas{namespace=\"$namespace\", statefulset=\"$workload\"}",
                "legendFormat": "desired",
            },
            {
                "expr": "kube_deployment_status_replicas_available{namespace=\"$namespace\", deployment=\"$workload\"} or kube_statefulset_status_replicas_ready{namespace=\"$namespace\", statefulset=\"$workload\"}",
                "legendFormat": "available",
            },
        ],
    })
    y += 8

    panels.append({
        "type": "timeseries",
        "title": "Restarts (last 1h)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (increase(kube_pod_container_status_restarts_total{namespace=\"$namespace\", pod=~\"$pod\"}[1h]))",
                "legendFormat": "{{pod}}/{{container}}",
            }
        ],
    })
    panels.append({
        "type": "timeseries",
        "title": "Restarts (last 24h)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (increase(kube_pod_container_status_restarts_total{namespace=\"$namespace\", pod=~\"$pod\"}[24h]))",
                "legendFormat": "{{pod}}/{{container}}",
            }
        ],
    })
    y += 8

    panels.append({
        "type": "timeseries",
        "title": "OOMKilled count (last 1h)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (max_over_time(kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\", namespace=\"$namespace\", pod=~\"$pod\"}[1h]))",
                "legendFormat": "{{pod}}/{{container}}",
            }
        ],
    })
    panels.append({
        "type": "timeseries",
        "title": "OOMKilled count (last 24h)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (max_over_time(kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\", namespace=\"$namespace\", pod=~\"$pod\"}[24h]))",
                "legendFormat": "{{pod}}/{{container}}",
            }
        ],
    })
    y += 8

    panels.append({
        "type": "timeseries",
        "title": "Memory working set (current)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (container_memory_working_set_bytes{namespace=\"$namespace\", pod=~\"$pod\", container!=""})",
                "legendFormat": "{{pod}}/{{container}}",
            }
        ],
    })
    panels.append({
        "type": "timeseries",
        "title": "Memory p95 (1h / 24h)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "quantile_over_time(0.95, container_memory_working_set_bytes{namespace=\"$namespace\", pod=~\"$pod\", container!=""}[1h])",
                "legendFormat": "p95 1h {{pod}}/{{container}}",
            },
            {
                "expr": "quantile_over_time(0.95, container_memory_working_set_bytes{namespace=\"$namespace\", pod=~\"$pod\", container!=""}[24h])",
                "legendFormat": "p95 24h {{pod}}/{{container}}",
            }
        ],
    })
    y += 8

    panels.append({
        "type": "timeseries",
        "title": "Usage vs limits (memory)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (container_memory_working_set_bytes{namespace=\"$namespace\", pod=~\"$pod\", container!=""})",
                "legendFormat": "usage {{pod}}/{{container}}",
            },
            {
                "expr": "sum by (pod,container) (kube_pod_container_resource_limits{namespace=\"$namespace\", pod=~\"$pod\", resource=\"memory\"})",
                "legendFormat": "limit {{pod}}/{{container}}",
            },
        ],
    })
    panels.append({
        "type": "timeseries",
        "title": "Usage/limit ratio (memory)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (container_memory_working_set_bytes{namespace=\"$namespace\", pod=~\"$pod\", container!=""}) / sum by (pod,container) (kube_pod_container_resource_limits{namespace=\"$namespace\", pod=~\"$pod\", resource=\"memory\"})",
                "legendFormat": "ratio {{pod}}/{{container}}",
            }
        ],
    })
    y += 8

    panels.append({
        "type": "timeseries",
        "title": "CPU usage vs requests",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "sum by (pod,container) (rate(container_cpu_usage_seconds_total{namespace=\"$namespace\", pod=~\"$pod\", container!=""}[5m]))",
                "legendFormat": "usage {{pod}}/{{container}}",
            },
            {
                "expr": "sum by (pod,container) (kube_pod_container_resource_requests{namespace=\"$namespace\", pod=~\"$pod\", resource=\"cpu\"})",
                "legendFormat": "request {{pod}}/{{container}}",
            }
        ],
    })
    panels.append({
        "type": "logs",
        "title": "Logs (Loki)",
        "datasource": "Loki",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "{namespace=\"$namespace\", pod=~\"$pod\", container=~\"$container\"}",
            }
        ],
    })

    dash["panels"] = panels
    return dash


def overview_dashboard():
    dash = dashboard_common("Overview: Top Apps", "k8s-overview-apps", ["kubernetes", "overview"]) 
    dash["templating"] = {
        "list": [
            {
                "name": "namespace",
                "type": "query",
                "datasource": "Prometheus",
                "query": "label_values(kube_pod_info, namespace)",
                "refresh": 1,
                "includeAll": True,
                "multi": True,
            }
        ]
    }
    panels = []
    y = 0

    panels.append({
        "type": "table",
        "title": "Top apps by restarts (last 1h)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "topk(10, sum by (owner_name) (increase(kube_pod_container_status_restarts_total{namespace=~\"$namespace\"}[1h]) * on(namespace,pod) group_left(owner_name, owner_kind) kube_pod_owner{owner_kind=~\"Deployment|StatefulSet\"}))",
                "format": "table",
            }
        ],
    })
    panels.append({
        "type": "table",
        "title": "Top apps by OOMKilled (last 24h)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "topk(10, sum by (owner_name) (max_over_time(kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\", namespace=~\"$namespace\"}[24h]) * on(namespace,pod) group_left(owner_name, owner_kind) kube_pod_owner{owner_kind=~\"Deployment|StatefulSet\"}))",
                "format": "table",
            }
        ],
    })
    y += 8

    panels.append({
        "type": "table",
        "title": "Top apps by memory p95 (last 1h)",
        "gridPos": {"x": 0, "y": y, "w": 12, "h": 8},
        "targets": [
            {
                "expr": "topk(10, sum by (owner_name) (quantile_over_time(0.95, container_memory_working_set_bytes{namespace=~\"$namespace\", container!=""}[1h]) * on(namespace,pod) group_left(owner_name, owner_kind) kube_pod_owner{owner_kind=~\"Deployment|StatefulSet\"}))",
                "format": "table",
            }
        ],
    })
    panels.append({
        "type": "text",
        "title": "Kyverno violations (TODO)",
        "gridPos": {"x": 12, "y": y, "w": 12, "h": 8},
        "options": {
            "mode": "markdown",
            "content": "Kyverno metrics not detected in Prometheus. TODO: expose Kyverno metrics endpoint and add ServiceMonitor to scrape policy violations."
        }
    })

    dash["panels"] = panels
    return dash


def write_configmap(dash, filename):
    name_base = f"grafana-dashboard-{dash['uid']}"
    name = truncate_name(slugify(name_base), 50)
    cm_name = name
    json_str = json.dumps(dash, indent=2)
    yaml = (
        "apiVersion: v1\n"
        "kind: ConfigMap\n"
        "metadata:\n"
        f"  name: {cm_name}\n"
        "  namespace: observability\n"
        "  labels:\n"
        "    grafana_dashboard: \"1\"\n"
        "data:\n"
        f"  {dash['uid']}.json: |\n"
        f"{indent(json_str, '    ')}\n"
    )
    (out_dir / filename).write_text(yaml, encoding="utf-8")

# Overview dashboard
write_configmap(overview_dashboard(), "overview-apps.yaml")

# Per-app dashboards
for w in workloads:
    dash = app_dashboard(w)
    fname = f"app-{slugify(w['namespace'])}-{slugify(w['name'])}.yaml"
    write_configmap(dash, fname)

print(f"\nDashboards written to: {out_dir}")
PY
