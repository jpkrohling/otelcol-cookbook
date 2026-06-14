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
| `grafana-cloud/` | recovered | → `starters/grafana-cloud/` (validated locally vs a basicauth receiver; concept = basicauth + `${env:}`) |
| `grafana-cloud-from-kubernetes/` | recovered | → `mains/grafana-cloud-from-kubernetes/` (secret handling; validated vs in-cluster basicauth backend) |
| `kafka-on-kubernetes/` | recovered | → `mains/kafka-on-kubernetes/` |
| `log-cleanup/` (redaction) | recovered | → `starters/log-redaction/` |
| `log-cleanup/dedup.yml` (orphan logdedup) | recovered | → `starters/log-deduplication/` |
| `ottl/example-01/` | recovered | → `starters/ottl-transformations/` (metrics fixture dropped: malformed JSON) |
| `ottl/redact-pii/` | recovered | → `starters/redact-pii/` |
| `ottl/tail-sampling-basics/` | recovered | → `starters/tail-sampling-basics/` |
| `own-telemetry/` | recovered | → `starters/own-telemetry/` |
| `probabilistic-sampler-logs/` | recovered | → `starters/probabilistic-sampler-logs/` |
| `profiling-the-collector/` | recovered | → `mains/profiling-the-collector/` (pprof endpoint validated; dropped stale Pyroscope values.yaml) |
| `remove-health-checks/` | recovered | → `starters/remove-health-checks/` |
| `scalable-tail-sampling/` | recovered | → `mains/scalable-tail-sampling/` (dropped otelcol-simple.yaml: stray private-image file) |
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
| `ratatouille/simple/{debug-26557,issue5610,contrib-9086-*}.yaml` | dropped | issue-repro scratch files (deprecated `logging`/`loki`/jaeger exporters) |
| `ratatouille/simple/{auth,receiver-auth,oidc-auth-agent,oidc-auth-collector,complete-auth,complete-oauth}.{yml,yaml}` | dropped | basicauth/OIDC/oauth2client all covered by `starters/auth/` |
| `ratatouille/simple/receiver-tls.yml` | dropped | covered by `starters/tls/` |
| `ratatouille/simple/{include,include-debug-exporter}.yaml` | dropped | `${file:}` include covered by `starters/decompose-config/` |
| `ratatouille/simple/resilient-log-pipeline.yaml` | dropped | logs twin of `starters/persistent-queue/`; same file_storage queue concept |
| `ratatouille/simple/{rejekts,rejekts-local}.yaml` | dropped | conference demo; concepts split across grafana-cloud + persistent-queue + own-telemetry |
| `ratatouille/simple/{simple,otelcol-simple}.yaml` | dropped | trivial nop configs (one used a private image); no recipe value |
| `ratatouille/simple/jaegerremotesampling.yaml` | recovered | → `starters/jaeger-remote-sampling/` (file source; remote-source variant documented as alternative) |
| `ratatouille/simple/count-before-sampling.yaml` | recovered | → `starters/count-before-sampling/` (dropped unused probabilistic_sampler; `logging`→`debug`) |
| `ratatouille/ottl/sensitive-log-body copy.yaml` | dropped | literal duplicate of `sensitive-log-body.yaml` |
| `ratatouille/ottl/sensitive-log-body.yaml` | recovered | → `starters/redact-log-body/` (log-body regex redaction; distinct from attribute-level redact-pii) |
| `ratatouille/tail-sampling/{always-on,probabilistic,latency→root-longer,vip,not-vip,and,multiple,multiple-ottl,only-2-percent...}.yaml` + README | recovered | → `desserts/tail-sampling-tasting-menu/` (consolidated showcase of all policy types + composition) |
| `ratatouille/tail-sampling/tail-sampling-with-spanmetrics.yaml` | merged | spanmetrics-before-sampling → covered by `starters/span-metrics-connector/` + `starters/count-before-sampling/` fan-out |
| `ratatouille/ottl/tail-sampling.yaml` | merged | ottl_condition policy → folded into tail-sampling-tasting-menu Key details |
| `ratatouille/routing/conn-tenants.yaml` | recovered | → `starters/tenant-routing/` (routing connector; `logging`→`debug`, `condition`+`context`) |
| `ratatouille/routing/{proc-tenants,two-matching-routes}.yaml` | dropped | deprecated routingprocessor; superseded by the routing connector in tenant-routing |
| `ratatouille/ottl/routing.yml` | merged | routing connector w/ `delete_key` statement → folded into tenant-routing Key details |
| `ratatouille/resilient/{wal,queues}.yaml` | recovered | → `starters/persistent-queue/` (disk-backed sending queue; `queues.yaml` in-memory variant folded into Key details) |
| `ratatouille/resilient/{agent,backend}.yaml` | merged | kafka-buffer pattern → covered by `mains/kafka-on-kubernetes/`; noted as alternative in persistent-queue |
| `ratatouille/ottl/*` | pending | triage individually |
| `ratatouille/kubernetes/target-allocator.yaml` | dropped | older/simpler dup of recovered `mains/target-allocator/` |
| `ratatouille/kubernetes/{sidecar-cr,sidecar-workload}.yaml` | recovered | → `mains/sidecar-injection/` (Operator injects mode:sidecar collector; validated as native sidecar) |
| `ratatouille/kubernetes/{manual-sidecar,workload}.yaml` | dropped | manual (pre-Operator) sidecar boilerplate superseded by injection; nginx sample unused |
| `ratatouille/kubernetes/otelcol.yaml` | recovered | → `mains/kubernetes-cluster-telemetry/` (k8s_cluster + k8s_events; Grafana Cloud dest swapped for debug) |
| `ratatouille/kubernetes/podslogs/otelcol.yaml` | recovered | → `mains/pod-logs-collection/` (daemonset filelog + container parser; added self-log exclude; debug dest) |
| `ratatouille/grafana/loki-receiver-auth.yaml` | recovered | → `starters/loki-receiver/` (loki receiver + basicauth; `logging`→`debug`) |
| `ratatouille/load-balancing-exporter/` | merged | loadbalancing exporter + k8s resolver already covered by `mains/scalable-tail-sampling/` |
