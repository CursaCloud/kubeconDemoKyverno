import subprocess
import json
from collections import defaultdict

THRESHOLD = 5  # umbral de fricción

def get_policy_reports(namespace=None):
    cmd = ["kubectl", "get", "policyreports", "-A", "-o", "json"]
    if namespace:
        cmd = ["kubectl", "get", "policyreports", "-n", namespace, "-o", "json"]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("Error fetching policy reports:", result.stderr)
        exit(1)

    return json.loads(result.stdout)


def analyze_violations(data):
    violations_by_namespace = defaultdict(lambda: defaultdict(int))

    for item in data.get("items", []):
        namespace = item["metadata"].get("namespace", "unknown")
        results = item.get("results", [])

        for r in results:
            policy = r.get("policy", "unknown")
            violations_by_namespace[namespace][policy] += 1

    return violations_by_namespace


def print_summary(violations):
    print("\n📊 Kyverno Violation Summary\n")

    for namespace, policies in violations.items():
        total = sum(policies.values())
        print(f"Namespace: {namespace}")
        print(f"  Total Violations: {total}")

        for policy, count in sorted(policies.items(), key=lambda x: x[1], reverse=True):
            status = "⚠️  Friction Detected" if count > THRESHOLD else "OK"
            print(f"    - {policy}: {count}  → {status}")

        print()


if __name__ == "__main__":
    data = get_policy_reports()
    violations = analyze_violations(data)
    print_summary(violations)