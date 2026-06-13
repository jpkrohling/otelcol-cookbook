# Cookbook Refactoring — Pilot Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the new culinary-course structure (scaffold + tracking + index) and migrate three pilot recipes through the full recover → modernize → smoke-test → document → commit loop, to validate the migration workflow before doing the rest.

**Architecture:** Course folders (`starters/`, `mains/`, `desserts/`, `sides/`) replace the flat layout. `_drawer/` becomes `sides/`. A hand-maintained `MIGRATION.md` tracks every legacy recipe/fragment's status; the root `README.md` carries a topical index table. Each recipe is migrated in its own commit. Validation is a runtime smoke test: local recipes run via the collector Docker image with `telemetrygen`; Kubernetes recipes deploy to a real k3d cluster with the OpenTelemetry Operator.

**Tech Stack:** OpenTelemetry Collector Contrib (Docker image `otel/opentelemetry-collector-contrib:0.154.0`), `telemetrygen` (image `ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:0.154.0`), OpenTelemetry Operator `v0.153.0`, k3d, kubectl, docker.

**Reference spec:** `docs/superpowers/specs/2026-06-12-cookbook-refactoring-design.md`

**Note on "tests":** This repo has no unit-test framework. The TDD analogue here is the **runtime smoke test** — each recipe's "failing test" is running the validation command and observing the expected telemetry output. A recipe is not "done" until its smoke test produces the expected output.

---

## File Structure

Created in this batch:

- `MIGRATION.md` — root-level tracking doc (full inventory + status).
- `sides/` — renamed from `_drawer/` (git move, preserves history).
- `starters/log-redaction/` — migrated from `log-cleanup/` (the documented redaction recipe).
- `starters/blocking-exporter/` — migrated from `ratatouille/simple/blocking.yaml`.
- `mains/target-allocator/` — migrated from `target-allocator/`.
- `README.md` — root: add topical index table; update LGTM/prometheus paths to `sides/`.

Not created yet (recorded as `pending` in `MIGRATION.md` only): all other legacy recipes and
ratatouille fragments, including `log-cleanup/dedup.yml` (the orphan `logdedup` fragment).

---

## Task 0: Scaffold structure, tracking doc, and index

**Files:**
- Create: `starters/.gitkeep`, `mains/.gitkeep`, `desserts/.gitkeep`
- Move: `_drawer/` → `sides/`
- Create: `MIGRATION.md`
- Modify: `README.md` (index table; `_drawer` → `sides` path references)

- [ ] **Step 1: Confirm latest versions still match the plan's pins**

```bash
curl -s "https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest" | grep -o '"tag_name": *"[^"]*"' | head -1
curl -s "https://api.github.com/repos/open-telemetry/opentelemetry-operator/releases/latest" | grep -o '"tag_name": *"[^"]*"' | head -1
```

Expected: collector `v0.154.0`, operator `v0.153.0`. If newer, use the newer versions
everywhere this plan references `0.154.0` / `v0.153.0` and note it.

- [ ] **Step 2: Create empty course directories**

```bash
mkdir -p starters mains desserts
touch starters/.gitkeep mains/.gitkeep desserts/.gitkeep
```

- [ ] **Step 3: Move `_drawer/` to `sides/` preserving history**

```bash
git mv _drawer sides
```

Run `ls sides/` — Expected: `lgtm  prometheus-instrumented-application  README.md`.

- [ ] **Step 4: Update root README references from `_drawer` to `sides`**

In `README.md`, change the LGTM Kubernetes apply line and any other `_drawer` path:

```
kubectl apply -f sides/lgtm/lgtm.yaml
```

Run: `grep -rn "_drawer" README.md` — Expected: no matches.

- [ ] **Step 5: Add the topical index table to the root README**

Insert this section in `README.md` immediately after the `## 📔 Recipes` heading paragraph
(replace the "organically grown / ratatouille" paragraph, since ratatouille is being dissolved):

```markdown
Recipes are organized as a menu, by depth of effort:

- **`starters/`** — quick, local, single-concept recipes
- **`mains/`** — substantial, often Kubernetes, real-world recipes
- **`desserts/`** — advanced showcases & niceties
- **`sides/`** — shared building blocks reused by other recipes

### Index

| Recipe | Course | Signals | Runs on | Key components |
|---|---|---|---|---|
| [log-redaction](starters/log-redaction/) | starters | logs | local | transformprocessor |
| [blocking-exporter](starters/blocking-exporter/) | starters | traces | local | otlpexporter |
| [target-allocator](mains/target-allocator/) | mains | metrics | Kubernetes | targetallocator, prometheusreceiver |
```

(Rows are added as each recipe is migrated. The three above are pre-seeded for the pilot; if a
later step changes a recipe's name, update its row to match.)

- [ ] **Step 6: Create `MIGRATION.md` with the full inventory**

Create `MIGRATION.md`:

```markdown
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
| `log-cleanup/` (redaction) | pending | → `starters/log-redaction/` |
| `log-cleanup/dedup.yml` (orphan logdedup) | pending | own recipe, e.g. `starters/log-deduplication/` |
| `ottl/example-01/` | pending | |
| `ottl/redact-pii/` | pending | |
| `ottl/tail-sampling-basics/` | pending | |
| `own-telemetry/` | pending | |
| `probabilistic-sampler-logs/` | pending | |
| `profiling-the-collector/` | pending | |
| `remove-health-checks/` | pending | |
| `scalable-tail-sampling/` | pending | |
| `span-metrics-connector/` | pending | |
| `target-allocator/` | pending | → `mains/target-allocator/` |
| `tls/` | pending | |

## Shared resources

| Source | Status | Destination / Note |
|---|---|---|
| `_drawer/lgtm/` | recovered | → `sides/lgtm/` |
| `_drawer/prometheus-instrumented-application/` | recovered | → `sides/prometheus-instrumented-application/` |

## ratatouille fragments

| Source | Status | Destination / Note |
|---|---|---|
| `ratatouille/simple/blocking.yaml` | pending | → `starters/blocking-exporter/` |
| `ratatouille/simple/*` (other) | pending | triage individually |
| `ratatouille/tail-sampling/*` | pending | triage individually |
| `ratatouille/routing/*` | pending | triage individually |
| `ratatouille/resilient/*` | pending | triage individually |
| `ratatouille/ottl/*` | pending | triage individually |
| `ratatouille/kubernetes/*` | pending | triage individually |
| `ratatouille/grafana/*` | pending | triage individually |
| `ratatouille/load-balancing-exporter/` | pending | triage individually |
```

- [ ] **Step 7: Verify nothing else still points at `_drawer`**

Run: `grep -rn "_drawer" . --include=*.md --include=*.yaml --include=*.yml | grep -v docs/superpowers`
Expected: no matches (every reference now uses `sides/`). Fix any that remain.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "refactor: scaffold course structure, MIGRATION.md, root index

Add starters/mains/desserts course dirs, rename _drawer -> sides, add the
migration tracking doc with full inventory, and seed the root README topical
index. No recipes migrated yet.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 1: Migrate `log-cleanup` → `starters/log-redaction/`

The documented recipe redacts CPF and Brazilian phone patterns from logs via the transform
processor. Only the documented `otelcol.yaml` + README migrate here; `dedup.yml` stays behind
as a `pending` fragment.

**Files:**
- Create: `starters/log-redaction/otelcol.yaml`
- Create: `starters/log-redaction/README.md`
- Delete: `log-cleanup/otelcol.yaml`, `log-cleanup/README.md`
- Move: `log-cleanup/dedup.yml` → keep for now (see Step 7)
- Modify: `MIGRATION.md`, `README.md` (index row already seeded — confirm name)

- [ ] **Step 1: Create the recipe directory and config**

```bash
mkdir -p starters/log-redaction
```

Create `starters/log-redaction/otelcol.yaml` (modernized: explicit endpoints, which current
collector versions expect rather than empty protocol blocks):

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  transform:
    log_statements:
      - context: log
        statements:
          - replace_pattern(log.body, "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", "<redacted>")
          - replace_all_patterns(log.attributes, "value", "\\(\\d{2}\\)\\s+\\d{5}-\\d{4}", "<redacted>")

exporters:
  debug:
    verbosity: detailed

service:
  pipelines:
    logs:
      receivers: [otlp]
      processors: [transform]
      exporters: [debug]
```

- [ ] **Step 2: Smoke test — start the collector (the "test harness")**

```bash
docker run -d --rm --name otelcol-redaction -p 4317:4317 \
  -v "$(pwd)/starters/log-redaction/otelcol.yaml:/etc/otelcol-contrib/config.yaml" \
  otel/opentelemetry-collector-contrib:0.154.0
sleep 3
docker logs otelcol-redaction 2>&1 | tail -5
```

Expected: log line `Everything is ready. Begin running and processing data.` and no config
errors. If the collector exits on a config error (e.g. a renamed OTTL path), fix
`otelcol.yaml`, then re-run this step.

- [ ] **Step 3: Send logs containing a CPF and a phone number**

```bash
docker run --rm ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:0.154.0 \
  logs --otlp-insecure --otlp-endpoint host.docker.internal:4317 --logs 1 \
  --body "User with CPF 123.456.789-00 logged in" \
  --telemetry-attributes 'phone="(12) 34567-8912"'
```

Expected: telemetrygen exits 0 with `logs are successfully sent`.

- [ ] **Step 4: Verify the redaction in the collector output**

```bash
docker logs otelcol-redaction 2>&1 | grep -A2 -i "body\|phone"
```

Expected: the log body shows `User with CPF <redacted> logged in` and the `phone` attribute
value shows `<redacted>`. If patterns are NOT redacted, the OTTL statements or the regex need
fixing — fix `otelcol.yaml` and re-run Steps 2–4.

- [ ] **Step 5: Tear down the harness**

```bash
docker rm -f otelcol-redaction
```

- [ ] **Step 6: Write the README to the contract**

Create `starters/log-redaction/README.md`:

````markdown
# 🍜 Recipe: Log Redaction

Redact sensitive patterns from logs before export using the transform processor. This recipe
redacts Brazilian CPF numbers (`###.###.###-##`) from log bodies and phone numbers
(`(##) #####-####`) from log attributes, replacing each match with `<redacted>`.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | transformprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/log-redaction/otelcol.yaml
   ```

2. Send a log containing a CPF and a phone number:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "User with CPF 123.456.789-00 logged in" --telemetry-attributes 'phone="(12) 34567-8912"'
   ```

3. Watch the collector output. The log body should read `User with CPF <redacted> logged in`
   and the `phone` attribute value should be `<redacted>`.

## 🎯 Key details

- `replace_pattern(log.body, ...)` rewrites the matched substring inside the log body.
- `replace_all_patterns(log.attributes, "value", ...)` scans every attribute *value* (not key)
  for the pattern and rewrites matches.
- Both run in the `log` OTTL context.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
````

- [ ] **Step 7: Finalize — remove originals, keep the orphan, update tracking**

Delete only the two documented files. Leave `dedup.yml` exactly where it is — it is a separate,
undocumented fragment that gets its own future recipe, so it stays `pending`.

```bash
git rm log-cleanup/otelcol.yaml log-cleanup/README.md
ls log-cleanup/
```

Expected: `dedup.yml` is the only remaining file in `log-cleanup/`.

In `MIGRATION.md`, set the `log-cleanup/ (redaction)` row Status to `recovered` and confirm the
`dedup.yml` row stays `pending`. In `README.md`, confirm the index row reads `log-redaction`
(seeded in Task 0 — no change needed).

- [ ] **Step 8: Commit this migration on its own**

```bash
git add -A
git commit -m "refactor: migrate log-cleanup -> starters/log-redaction

Modernize OTTL config (explicit gRPC endpoint), rewrite README to the recipe
contract with metadata table, validate redaction via Docker smoke test against
collector 0.154.0. The orphan logdedup fragment (dedup.yml) stays pending.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Migrate `ratatouille/simple/blocking.yaml` → `starters/blocking-exporter/`

Demonstrates disabling the exporter sending queue so the collector blocks (synchronously
applies backpressure / retries) instead of accepting and buffering data. Proves the
ratatouille dissolve/triage path.

**Files:**
- Create: `starters/blocking-exporter/otelcol.yaml`
- Create: `starters/blocking-exporter/README.md`
- Delete: `ratatouille/simple/blocking.yaml`
- Modify: `MIGRATION.md`

- [ ] **Step 1: Create the recipe directory and modernized config**

```bash
mkdir -p starters/blocking-exporter
```

Create `starters/blocking-exporter/otelcol.yaml` (explicit endpoint; drop the empty
`processors:` block; keep the unreachable endpoint so the blocking behavior is observable):

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

exporters:
  otlp:
    endpoint: example.com:4317
    sending_queue:
      enabled: false

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp]
```

- [ ] **Step 2: Smoke test — start the collector**

```bash
docker run -d --rm --name otelcol-blocking -p 4317:4317 \
  -v "$(pwd)/starters/blocking-exporter/otelcol.yaml:/etc/otelcol-contrib/config.yaml" \
  otel/opentelemetry-collector-contrib:0.154.0
sleep 3
docker logs otelcol-blocking 2>&1 | tail -5
```

Expected: `Everything is ready. Begin running and processing data.` with no config error
(this validates that `sending_queue.enabled: false` is still accepted on the otlp exporter in
0.154.0). If it errors, fix the config and re-run.

- [ ] **Step 3: Send traces and observe the blocking/retry behavior**

```bash
docker run --rm ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:0.154.0 \
  traces --otlp-insecure --otlp-endpoint host.docker.internal:4317 --traces 5
docker logs otelcol-blocking 2>&1 | tail -20
```

Expected: because the queue is disabled and `example.com:4317` is unreachable, the collector
logs export failures / retry attempts inline (e.g. `Exporting failed. Will retry the request`)
rather than silently buffering — this is the blocking/backpressure behavior the recipe
demonstrates.

- [ ] **Step 4: Tear down**

```bash
docker rm -f otelcol-blocking
```

- [ ] **Step 5: Write the README to the contract**

Create `starters/blocking-exporter/README.md`:

````markdown
# 🍜 Recipe: Blocking Exporter

By default the OpenTelemetry Collector accepts data into an asynchronous sending queue and
returns success to the client immediately. This recipe disables the sending queue so the
exporter behaves synchronously: the collector applies backpressure to the client and retries
inline until the data is sent or the request times out.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | otlpexporter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/blocking-exporter/otelcol.yaml
   ```

2. Send some traces:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 5
   ```

3. Watch the collector output. Because the queue is disabled and the configured endpoint
   (`example.com:4317`) is unreachable, the collector logs export failures and retry attempts
   inline instead of buffering. Point the exporter at a reachable endpoint to see it succeed
   synchronously.

## 🎯 Key details

- `sending_queue.enabled: false` removes the in-memory queue between the pipeline and the
  exporter, making export synchronous (the retry mechanism still applies).
- Use this when you prefer backpressure over buffering — the producer slows down rather than
  the collector accumulating unsent data in memory.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
````

- [ ] **Step 6: Finalize — remove original, update tracking and index**

```bash
git rm ratatouille/simple/blocking.yaml
```

In `MIGRATION.md`, set the `ratatouille/simple/blocking.yaml` row Status to `recovered`. The
root README index row was seeded in Task 0 — confirm it is present and correct.

- [ ] **Step 7: Commit this migration on its own**

```bash
git add -A
git commit -m "refactor: migrate ratatouille blocking.yaml -> starters/blocking-exporter

First ratatouille fragment promoted to a documented recipe: disabling the
exporter sending queue for synchronous/backpressure behavior. Validated via
Docker smoke test against collector 0.154.0.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Migrate `target-allocator` → `mains/target-allocator/`

The Kubernetes pilot. Exercises the full k3d + cert-manager + operator deploy path and depends
on the prometheus app now in `sides/`. Source files: `otelcol-cr.yaml`, `role.yaml`, `svc.yaml`,
`workload.yaml`, `README.md`.

**Files:**
- Create: `mains/target-allocator/{otelcol-cr.yaml,role.yaml,svc.yaml,workload.yaml,README.md}`
- Delete: `target-allocator/*` (after move)
- Modify: `MIGRATION.md`, root `README.md` index row paths

- [ ] **Step 1: Move the recipe files into the new course folder**

```bash
mkdir -p mains/target-allocator
git mv target-allocator/otelcol-cr.yaml mains/target-allocator/otelcol-cr.yaml
git mv target-allocator/role.yaml mains/target-allocator/role.yaml
git mv target-allocator/svc.yaml mains/target-allocator/svc.yaml
git mv target-allocator/workload.yaml mains/target-allocator/workload.yaml
git mv target-allocator/README.md mains/target-allocator/README.md
rmdir target-allocator
```

- [ ] **Step 2: Inspect the CR for deprecated fields against operator v0.153.0**

Read `mains/target-allocator/otelcol-cr.yaml`. Confirm: `spec.targetAllocator.enabled: true`
is present, `spec.mode` is set (`statefulset` or `deployment`), and the prometheus receiver
config is under `spec.config`. The operator v0.125→v0.153 deprecated
`spec.targetAllocator.prometheusCR.enabled` is now `spec.targetAllocator.prometheusCR:` block —
if the CR uses the old flat key, update it to the nested form. Capture the exact image tag in
`spec.image` (pin to a contrib `0.154.0` image if it pins an older one).

- [ ] **Step 3: Create the k3d cluster and install prerequisites**

```bash
k3d cluster create cookbook-pilot
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait --for=condition=Available deployments/cert-manager -n cert-manager --timeout=180s
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.153.0/opentelemetry-operator.yaml
kubectl wait --for=condition=Available deployments/opentelemetry-operator-controller-manager -n opentelemetry-operator-system --timeout=180s
```

Expected: both `kubectl wait` commands return `condition met`.

- [ ] **Step 4: Build and import the prometheus-instrumented application image**

```bash
docker build -t prometheus-instrumented-application:latest sides/prometheus-instrumented-application
k3d image import prometheus-instrumented-application:latest -c cookbook-pilot
```

Expected: `Successfully imported image(s)`.

- [ ] **Step 5: Install Prometheus CRDs, namespace, and the recipe (the "test")**

```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl create ns target-allocator-recipe
kubectl config set-context --current --namespace=target-allocator-recipe
kubectl apply -f mains/target-allocator/role.yaml
kubectl apply -f mains/target-allocator/otelcol-cr.yaml
kubectl apply -f mains/target-allocator/workload.yaml
kubectl apply -f mains/target-allocator/svc.yaml
```

Expected: each resource is created without admission errors. If the CR is rejected, the
operator's validating webhook message names the offending field — fix `otelcol-cr.yaml`
(Step 2) and re-apply.

- [ ] **Step 6: Verify the collector and target allocator are running and discovering targets**

```bash
kubectl get pods -n target-allocator-recipe
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=opentelemetry-collector -n target-allocator-recipe --timeout=120s
kubectl port-forward svc/collector-with-ta-targetallocator 8080:80 -n target-allocator-recipe &
PF_PID=$!
sleep 3
curl -s "http://localhost:8080/jobs" | head -20
kill $PF_PID
```

Expected: collector and target-allocator pods are `Running`; the `/jobs` endpoint returns JSON
listing at least one scrape job for the recipe's ServiceMonitor (proves the TA discovered the
prometheus app). If the service name differs, get it via
`kubectl get svc -n target-allocator-recipe` and adjust.

- [ ] **Step 7: Update the README to the contract**

Edit `mains/target-allocator/README.md`:
- Title stays `# 🍜 Recipe: Target Allocator`.
- Add the metadata table directly under the description:
  ```markdown
  | | |
  |---|---|
  | **Signals** | metrics |
  | **Runs on** | Kubernetes |
  | **Key components** | targetallocator, prometheusreceiver |
  ```
- Update file paths in the steps from `target-allocator/...` to `mains/target-allocator/...`.
- Fix the prometheus app link from `../_drawer/...` to `../../sides/prometheus-instrumented-application/`.
- Rename the final `## 😋 Versions` heading to `## 😋 Tested with` and pin:
  ```markdown
  - OpenTelemetry Operator v0.153.0
  - OpenTelemetry Collector Contrib v0.154.0
  ```

- [ ] **Step 8: Tear down the cluster**

```bash
k3d cluster delete cookbook-pilot
```

- [ ] **Step 9: Finalize tracking and index**

In `MIGRATION.md`, set the `target-allocator/` row Status to `recovered`. In root `README.md`,
confirm the index row path is `mains/target-allocator/` (seeded in Task 0).

- [ ] **Step 10: Commit this migration on its own**

```bash
git add -A
git commit -m "refactor: migrate target-allocator -> mains/target-allocator

Move recipe into the mains course, modernize the CR for operator v0.153.0, add
the metadata table, fix sides/ paths, standardize the Tested-with heading.
Validated end-to-end on a k3d cluster: TA discovered the prometheus app's
ServiceMonitor targets.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Pilot review

**Files:** none (review only)

- [ ] **Step 1: Verify the tree state**

```bash
ls starters mains desserts sides
git log --oneline -5
grep -c "recovered" MIGRATION.md
```

Expected: `starters/` holds `log-redaction` + `blocking-exporter`; `mains/` holds
`target-allocator`; one commit per migration plus the scaffold commit; three `recovered` rows
(plus the two `sides/` resources) in `MIGRATION.md`.

- [ ] **Step 2: Confirm root README index matches reality**

```bash
grep -A6 "### Index" README.md
```

Expected: three rows whose links resolve to existing directories.

- [ ] **Step 3: Summarize for the user**

Report: what worked in the workflow, anything awkward (Docker networking, k3d timing, CR
modernization friction), and propose any adjustments to the per-recipe loop before migrating
the remaining ~17 recipes and the ratatouille fragments course by course.

---

## Self-Review Notes

- **Spec coverage:** structure (Task 0), per-recipe contract (Tasks 1–3 READMEs + metadata
  table), runtime smoke-test validation (each task's test steps), ratatouille dissolve (Task 2),
  per-recipe commits (every task ends in its own commit), MIGRATION.md tracking (Task 0 + each
  finalize step), root index (Task 0 + confirmations). All covered.
- **Discovered deviation from spec:** `log-cleanup` documents redaction, not dedup — plan
  migrates it as `starters/log-redaction/` and records the orphan `dedup.yml` as pending. Flag
  this to the user.
- **Version pins:** collector `0.154.0`, operator `v0.153.0`, telemetrygen `0.154.0` — Step 0.1
  re-confirms at execution time.
- **macOS networking:** `host.docker.internal` is used for telemetrygen → collector; correct
  for Docker Desktop on darwin.
