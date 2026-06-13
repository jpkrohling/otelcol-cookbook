# Migration Tracking

Status of every legacy recipe and `ratatouille/` fragment as we refactor into the
culinary-course structure. See `docs/superpowers/specs/2026-06-12-cookbook-refactoring-design.md`.

**Status values:** `pending` · `recovered` · `merged` (note target) · `dropped` (note why)

## Documented top-level recipes

| Source | Status | Destination / Note |
|---|---|---|
| `auth/` | pending | |
| `auto-instrumentation/` | pending | |
| `client-side-load-balancing/` | pending | |
| `decompose-config/` | pending | |
| `grafana-cloud/` | pending | |
| `grafana-cloud-from-kubernetes/` | pending | |
| `kafka-on-kubernetes/` | pending | |
| `log-cleanup/` (redaction) | recovered | → `starters/log-redaction/` |
| `log-cleanup/dedup.yml` (orphan logdedup) | pending | own recipe, e.g. `starters/log-deduplication/` |
| `ottl/example-01/` | pending | |
| `ottl/redact-pii/` | pending | |
| `ottl/tail-sampling-basics/` | pending | |
| `own-telemetry/` | recovered | → `starters/own-telemetry/` |
| `probabilistic-sampler-logs/` | pending | |
| `profiling-the-collector/` | pending | |
| `remove-health-checks/` | pending | |
| `scalable-tail-sampling/` | pending | |
| `span-metrics-connector/` | pending | |
| `target-allocator/` | recovered | → `mains/target-allocator/` |
| `tls/` | pending | |

## Shared resources

| Source | Status | Destination / Note |
|---|---|---|
| `_drawer/lgtm/` | recovered | → `sides/lgtm/` |
| `_drawer/prometheus-instrumented-application/` | recovered | → `sides/prometheus-instrumented-application/` |

## ratatouille fragments

| Source | Status | Destination / Note |
|---|---|---|
| `ratatouille/simple/blocking.yaml` | recovered | → `starters/blocking-exporter/` |
| `ratatouille/simple/*` (other) | pending | triage individually |
| `ratatouille/tail-sampling/*` | pending | triage individually |
| `ratatouille/routing/*` | pending | triage individually |
| `ratatouille/resilient/*` | pending | triage individually |
| `ratatouille/ottl/*` | pending | triage individually |
| `ratatouille/kubernetes/*` | pending | triage individually |
| `ratatouille/grafana/*` | pending | triage individually |
| `ratatouille/load-balancing-exporter/` | pending | triage individually |
