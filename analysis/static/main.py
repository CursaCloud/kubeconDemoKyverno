import subprocess
import json
import os
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Dict, Set, Tuple

THRESHOLD = 5  # friction threshold

# Non-negotiable security policies (CIS / hardening baseline).
# Add exact policy names here if your internal catalog already defines them.
NON_NEGOTIABLE_POLICIES = {
    "disallow-privileged-containers",
    "disallow-host-namespaces",
    "disallow-host-path",
    "require-run-as-non-root-user",
    "require-run-as-nonroot",
    "require-read-only-root-filesystem",
    "restrict-capabilities",
    "restrict-seccomp-strict",
    "require-network-policy",
    "disallow-latest-tag",
    "disallow-host-ports",
}

NON_NEGOTIABLE_KEYWORDS = (
    "cis",
    "pod-security",
    "psa",
    "security",
    "seccomp",
    "capabilit",
    "privileged",
    "hostpath",
    "host-path",
    "hostnamespace",
    "host-namespace",
    "non-root",
    "run-as-non-root",
    "read-only-root",
)


@dataclass
class Analysis:
    violations_by_namespace: Dict[str, Dict[str, int]] = field(default_factory=lambda: defaultdict(lambda: defaultdict(int)))
    violations_by_policy: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    violations_by_rule: Dict[Tuple[str, str], int] = field(default_factory=lambda: defaultdict(int))
    violations_by_kind: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    failing_resources_by_policy: Dict[str, Set[str]] = field(default_factory=lambda: defaultdict(set))
    namespaces_by_policy: Dict[str, Set[str]] = field(default_factory=lambda: defaultdict(set))
    result_by_policy: Dict[str, Dict[str, int]] = field(default_factory=lambda: defaultdict(lambda: defaultdict(int)))
    sample_messages_by_policy: Dict[str, str] = field(default_factory=dict)


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
    analysis = Analysis()

    for item in data.get("items", []):
        namespace = item["metadata"].get("namespace", "unknown")
        results = item.get("results", [])

        for r in results:
            policy = r.get("policy", "unknown")
            rule = r.get("rule", "unknown")
            result = r.get("result", "unknown").lower()
            message = r.get("message", "")
            resources = r.get("resources", [])

            analysis.violations_by_namespace[namespace][policy] += 1
            analysis.violations_by_policy[policy] += 1
            analysis.violations_by_rule[(policy, rule)] += 1
            analysis.namespaces_by_policy[policy].add(namespace)
            analysis.result_by_policy[policy][result] += 1

            if policy not in analysis.sample_messages_by_policy and message:
                analysis.sample_messages_by_policy[policy] = message

            for resource in resources:
                kind = resource.get("kind", "Unknown")
                name = resource.get("name", "unknown")
                ns = resource.get("namespace", namespace)
                analysis.violations_by_kind[kind] += 1
                analysis.failing_resources_by_policy[policy].add(f"{ns}/{kind}/{name}")

    return analysis


def is_non_negotiable_policy(policy_name):
    normalized = policy_name.lower()
    if normalized in NON_NEGOTIABLE_POLICIES:
        return True
    return any(k in normalized for k in NON_NEGOTIABLE_KEYWORDS)


def build_recommendations(analysis):
    recs = []
    total_violations = sum(analysis.violations_by_policy.values())

    if total_violations == 0:
        return ["No violations found. Keep the baseline and continuous monitoring."]

    top_policies = sorted(analysis.violations_by_policy.items(), key=lambda x: x[1], reverse=True)[:5]
    for policy, count in top_policies:
        spread_ns = len(analysis.namespaces_by_policy[policy])
        affected_resources = len(analysis.failing_resources_by_policy[policy])
        sample_msg = analysis.sample_messages_by_policy.get(policy, "").strip()
        sample_msg = sample_msg[:140] + "..." if len(sample_msg) > 140 else sample_msg
        policy_class = "non-negotiable (CIS/security)" if is_non_negotiable_policy(policy) else "tunable"

        if is_non_negotiable_policy(policy):
            recs.append(
                f"[{policy}] {count} violations ({policy_class}). "
                f"Do not relax this policy. Prioritize source-level remediation with templates, examples, and CI/CD guardrails. "
                f"Impact: {spread_ns} namespaces, {affected_resources} resources."
            )
        else:
            action = "temporarily move to Audit with an expiration date" if count > THRESHOLD * 3 else "refine match/exclude and error messages"
            recs.append(
                f"[{policy}] {count} violations ({policy_class}). Suggestion: {action}. "
                f"Impact: {spread_ns} namespaces, {affected_resources} resources."
            )

        if sample_msg:
            recs.append(f"  Example message: {sample_msg}")

    noisy_kinds = sorted(analysis.violations_by_kind.items(), key=lambda x: x[1], reverse=True)[:3]
    if noisy_kinds:
        kinds_txt = ", ".join(f"{k}={v}" for k, v in noisy_kinds)
        recs.append(
            f"Focus by resource type: {kinds_txt}. Build playbooks and snippets by kind to accelerate remediation."
        )

    return recs


def template_disallow_latest_tag():
    return """apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag-<business-unit>
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: require-immutable-image-tags
    match:
      any:
      - resources:
          kinds: ["Pod"]
          namespaces: ["<team-namespace-1>", "<team-namespace-2>"]
    exclude:
      any:
      - resources:
          namespaces: ["<platform-exception-ns>"]
    validate:
      message: "Images must use immutable tags or digest. Team: <owner-team>"
      pattern:
        spec:
          containers:
          - image: "!*:latest"
"""


def template_restrict_privileged():
    return """apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-privileged-<business-unit>
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: block-privileged
    match:
      any:
      - resources:
          kinds: ["Pod"]
          selector:
            matchLabels:
              business-unit: "<business-unit>"
    validate:
      message: "Privileged containers are not allowed. Exception process: <ticket-system>"
      pattern:
        spec:
          containers:
          - securityContext:
              privileged: false
"""


def template_require_resources():
    return """apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resources-<workload-class>
spec:
  validationFailureAction: Audit
  background: true
  rules:
  - name: require-cpu-memory
    match:
      any:
      - resources:
          kinds: ["Deployment", "StatefulSet", "DaemonSet"]
          namespaces: ["<app-namespace>"]
    validate:
      message: "CPU/Memory requests & limits are mandatory. SLO tier: <tier>"
      pattern:
        spec:
          template:
            spec:
              containers:
              - resources:
                  requests:
                    cpu: "?*"
                    memory: "?*"
                  limits:
                    cpu: "?*"
                    memory: "?*"
"""


def template_require_labels():
    return """apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-business-labels
spec:
  validationFailureAction: Audit
  background: true
  rules:
  - name: require-cost-ownership-labels
    match:
      any:
      - resources:
          kinds: ["Deployment", "Service", "Ingress"]
    validate:
      message: "Required labels missing: owner/team/cost-center/data-classification"
      pattern:
        metadata:
          labels:
            owner: "?*"
            team: "?*"
            cost-center: "?*"
            data-classification: "<public|internal|restricted>"
"""


def template_require_network_policy():
    return """apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-networkpolicy-per-namespace
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: require-default-deny-networkpolicy
    match:
      any:
      - resources:
          kinds: ["Namespace"]
          selector:
            matchLabels:
              environment: "<prod|staging>"
    validate:
      message: "Each namespace must define a default deny NetworkPolicy."
      deny:
        conditions:
          any:
          - key: "{{ request.object.metadata.name }}"
            operator: NotIn
            value: ["<namespaces-with-networkpolicy-managed-externally>"]
"""


def build_policy_suggestions(analysis):
    suggestions = []
    top_policies = sorted(analysis.violations_by_policy.items(), key=lambda x: x[1], reverse=True)[:8]
    seen = set()

    for policy, _count in top_policies:
        p = policy.lower()
        if ("latest" in p or "tag" in p) and "latest-tag" not in seen:
            suggestions.append(("latest-tag", template_disallow_latest_tag()))
            seen.add("latest-tag")
        if ("privileged" in p or "capabilit" in p or "seccomp" in p) and "privileged" not in seen:
            suggestions.append(("privileged", template_restrict_privileged()))
            seen.add("privileged")
        if ("resource" in p or "limit" in p or "request" in p) and "resources" not in seen:
            suggestions.append(("resources", template_require_resources()))
            seen.add("resources")
        if ("label" in p or "annotation" in p) and "labels" not in seen:
            suggestions.append(("labels", template_require_labels()))
            seen.add("labels")
        if ("network" in p or "ingress" in p or "egress" in p) and "network-policy" not in seen:
            suggestions.append(("network-policy", template_require_network_policy()))
            seen.add("network-policy")

    if not suggestions:
        suggestions = [
            ("labels", template_require_labels()),
            ("resources", template_require_resources()),
        ]

    return suggestions


def save_policy_suggestions_to_files(suggestions, output_dir="analysis/static/generated-policies"):
    os.makedirs(output_dir, exist_ok=True)
    written_files = []

    for key, policy_yaml in suggestions:
        filename = f"{key}.yaml"
        full_path = os.path.join(output_dir, filename)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(policy_yaml)
        written_files.append(full_path)

    return written_files


def print_summary(analysis):
    print("\n📊 Kyverno Violation Summary\n")

    for namespace, policies in analysis.violations_by_namespace.items():
        total = sum(policies.values())
        print(f"Namespace: {namespace}")
        print(f"  Total Violations: {total}")

        for policy, count in sorted(policies.items(), key=lambda x: x[1], reverse=True):
            status = "⚠️  Friction Detected" if count > THRESHOLD else "OK"
            print(f"    - {policy}: {count}  → {status}")

        print()

    print("🔥 Top policies with friction")
    for policy, count in sorted(analysis.violations_by_policy.items(), key=lambda x: x[1], reverse=True)[:10]:
        status = "NON-NEGOTIABLE" if is_non_negotiable_policy(policy) else "Tunable"
        print(f"  - {policy}: {count} ({status})")
    print()

    print("📌 Non-negotiable policies (CIS/security)")
    nn = [(p, c) for p, c in analysis.violations_by_policy.items() if is_non_negotiable_policy(p)]
    if not nn:
        print("  - No non-negotiable policies with violations detected.")
    else:
        for policy, count in sorted(nn, key=lambda x: x[1], reverse=True):
            namespaces = len(analysis.namespaces_by_policy[policy])
            resources = len(analysis.failing_resources_by_policy[policy])
            print(f"  - {policy}: {count} violations | namespaces={namespaces} | resources={resources}")
    print()

    print("🛠️ Recommendations")
    for rec in build_recommendations(analysis):
        print(f"  - {rec}")
    print()

    suggestions = build_policy_suggestions(analysis)
    print("🧩 Suggested policy templates (customizable placeholders)")
    for key, policy_yaml in suggestions:
        print(f"\n# Template: {key}")
        print(policy_yaml)

    written_files = save_policy_suggestions_to_files(suggestions)
    print("\n💾 Generated files")
    for file_path in written_files:
        print(f"  - {file_path}")


if __name__ == "__main__":
    data = get_policy_reports()
    analysis = analyze_violations(data)
    print_summary(analysis)
