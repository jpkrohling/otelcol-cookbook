# Migration Tracking

Status of every legacy recipe and `ratatouille/` fragment as we refactor into the
culinary-course structure. See `docs/superpowers/specs/2026-06-12-cookbook-refactoring-design.md`.

**Status values:** `pending` · `recovered` · `merged` (note target) · `dropped` (note why)

## Documented top-level recipes

| Source | Status | Destination / Note |
|---|---|---|
| `auth/` | recovered | → `starters/auth/` |
| `auto-instrumentation/` | recovered | → `mains/auto-instrumentation/` |
| `client-side-load-balancing/` | recovered | → `mains/client-side-load-balancing/` |
| `decompose-config/` | recovered | → `starters/decompose-config/` |
| `grafana-cloud/` | pending | |
| `grafana-cloud-from-kubernetes/` | pending | |
| `kafka-on-kubernetes/` | pending | |
| `log-cleanup/` (redaction) | recovered | → `starters/log-redaction/` |
| `log-cleanup/dedup.yml` (orphan logdedup) | recovered | → `starters/log-deduplication/` |
| `ottl/example-01/` | recovered | → `starters/ottl-transformations/` (metrics fixture dropped: malformed JSON) |
| `ottl/redact-pii/` | recovered | → `starters/redact-pii/` |
| `ottl/tail-sampling-basics/` | recovered | → `starters/tail-sampling-basics/` |
| `own-telemetry/` | recovered | → `starters/own-telemetry/` |
| `probabilistic-sampler-logs/` | recovered | → `starters/probabilistic-sampler-logs/` |
| `profiling-the-collector/` | pending | |
| `remove-health-checks/` | recovered | → `starters/remove-health-checks/` |
| `scalable-tail-sampling/` | pending | |
| `span-metrics-connector/` | recovered | → `starters/span-metrics-connector/` |
| `target-allocator/` | recovered | → `mains/target-allocator/` |
| `tls/` | recovered | → `starters/tls/` |

## Shared resources

| Source | Status | Destination / Note |
|---|---|---|
| `_drawer/lgtm/` | recovered | → `sides/lgtm/` |
| `_drawer/prometheus-instrumented-application/` | recovered | → `sides/prometheus-instrumented-application/` |

## ratatouille fragments

| Source | Status | Destination / Note |
|---|---|---|
| `ratatouille/simple/blocking.yaml` | recovered | → `starters/blocking-exporter/` |
| `ratatouille/simple/logs-to-metrics.yaml` | recovered | → `starters/logs-to-metrics/` |
| `ratatouille/simple/*` (other) | pending | triage individually |
| `ratatouille/tail-sampling/*` | pending | triage individually |
| `ratatouille/routing/*` | pending | triage individually |
| `ratatouille/resilient/*` | pending | triage individually |
| `ratatouille/ottl/*` | pending | triage individually |
| `ratatouille/kubernetes/*` | pending | triage individually |
| `ratatouille/grafana/*` | pending | triage individually |
| `ratatouille/load-balancing-exporter/` | pending | triage individually |
