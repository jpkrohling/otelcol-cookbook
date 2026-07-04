# Access Logs to Metrics Recipe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `starters/access-logs-to-metrics`, a recipe converting HTTP access logs into a
semconv-named `http.server.request.duration` metric via the `signal_to_metrics` connector,
and mark `starters/logs-to-metrics` deprecated for this specific use case.

**Architecture:** A single Collector pipeline receives OTLP logs shaped like access-log
lines, an OTTL `transform` derives a normalized `http.route`, then a `forward` connector
fans the stream to (a) `signal_to_metrics`, emitting the histogram, and (b) a `filter` that
keeps only 5xx records as logs. No code — this is a config + documentation recipe, validated
by a runtime smoke test (Docker images, no locally installed binaries).

**Tech Stack:** OpenTelemetry Collector Contrib (Docker image `otel/opentelemetry-collector-contrib:0.155.0`), `telemetrygen` (Docker image `ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.155.0`).

## Global Constraints

- Config files are always `.yaml` (never `.yml`).
- Always use current, non-deprecated component type names in configs and in a recipe's own
  README metadata table: `transform` (not `transformprocessor`), `signal_to_metrics` (not
  `signaltometrics`), `forward`, `filter`.
- The top-level `README.md` recipe index keeps its own established style for the "Key
  components" column — legacy `xxxprocessor`/`xxxconnector` suffix names — for consistency
  with every existing row. Do not "fix" other rows; only add the new one in that same style.
- Each recipe README follows the fixed contract from `CLAUDE.md`: title, description,
  metadata table, 🧄 Ingredients, 🥣 Preparation, optional 🎯 Key details, 😋 Tested with.
- Version pins for this recipe: OpenTelemetry Collector Contrib v0.155.0, `telemetrygen`
  v0.155.0 (matches current repo-wide pins).
- Smoke-test locally via Docker (no local `otelcol-contrib`/`telemetrygen` binaries
  installed): collector image tag has **no** `v` prefix (`0.155.0`), telemetrygen image tag
  **requires** a `v` prefix (`v0.155.0`). Default config path inside the collector container
  is `/etc/otelcol-contrib/config.yaml`. On macOS/Docker Desktop, the telemetrygen container
  reaches the host-published collector via `--otlp-endpoint host.docker.internal:4317`.

---

## Task 1: Write the `access-logs-to-metrics` Collector config

**Files:**
- Create: `starters/access-logs-to-metrics/otelcol.yaml`

**Interfaces:**
- Produces: the pipeline this recipe's README (Task 2) and smoke test (Task 3) exercise.
  Exposes an OTLP gRPC receiver on `0.0.0.0:4317`. Expects incoming log records to carry
  log attributes `http.request.method` (string), `url.path` (string),
  `http.response.status_code` (int), `duration_ms` (int).

- [ ] **Step 1: Create the directory and write the config**

```bash
mkdir -p starters/access-logs-to-metrics
```

Write `starters/access-logs-to-metrics/otelcol.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  # derives a low-cardinality http.route from url.path, and converts the raw
  # duration attribute into the double-seconds value the histogram expects
  transform/access-log-route:
    log_statements:
      - context: log
        statements:
          - set(log.attributes["http.route"], log.attributes["url.path"])
          - replace_pattern(log.attributes["http.route"], "\\?.*$", "")
          - replace_pattern(log.attributes["http.route"], "/[0-9]+", "/{id}")
          - set(log.attributes["_duration_s"], Double(log.attributes["duration_ms"]) / 1000.0)

  # drops everything below 500, so only server-error access logs are kept as logs
  filter/keep-errors:
    logs:
      log_record:
        - 'log.attributes["http.response.status_code"] < 500'

exporters:
  debug/logs:
  debug/metrics:
    verbosity: detailed

connectors:
  forward:
  signal_to_metrics:
    logs:
      - name: http.server.request.duration
        description: HTTP server request duration (s) derived from access logs
        unit: s
        attributes:
          - key: http.request.method
          - key: http.response.status_code
          - key: http.route
        exponential_histogram:
          count: "1"
          value: log.attributes["_duration_s"]

service:
  pipelines:
    # the main logs pipeline derives http.route once, then fans out
    logs:
      receivers: [otlp]
      processors: [transform/access-log-route]
      exporters: [forward]

    # server errors are also kept as logs, for forensic debugging
    logs/errors:
      receivers: [forward]
      processors: [filter/keep-errors]
      exporters: [debug/logs]

    # every access log record is converted into a metric
    logs/metrics-source:
      receivers: [forward]
      exporters: [signal_to_metrics]

    metrics/access-logs:
      receivers: [signal_to_metrics]
      exporters: [debug/metrics]
```

- [ ] **Step 2: Validate the YAML parses**

Run: `python3 -c "import yaml, sys; yaml.safe_load(open('starters/access-logs-to-metrics/otelcol.yaml'))" && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add starters/access-logs-to-metrics/otelcol.yaml
git commit -m "feat: add access-logs-to-metrics recipe config"
```

---

## Task 2: Write the recipe README

**Files:**
- Create: `starters/access-logs-to-metrics/README.md`

**Interfaces:**
- Consumes: the config from Task 1 (`starters/access-logs-to-metrics/otelcol.yaml`), the
  exact pipeline/attribute names defined there.
- Produces: the documented `telemetrygen` commands and expected output that Task 3's smoke
  test must reproduce verbatim.

- [ ] **Step 1: Write the README**

Write `starters/access-logs-to-metrics/README.md`:

```markdown
# 🍜 Recipe: Access Logs to Metrics

High-volume HTTP access logs are cheap individually but expensive in aggregate — one line
per request, mostly noise. This recipe converts them into a single
`http.server.request.duration` metric, dimensioned by method, status, and a normalized
route, while keeping server-error (5xx) lines as logs for forensic debugging.

| | |
|---|---|
| **Signals** | logs → logs + metrics |
| **Runs on** | local binary |
| **Key components** | transform, signal_to_metrics, forward, filter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/access-logs-to-metrics/otelcol.yaml
   ```

2. Send a batch of successful requests hitting the same route family with different ids:
   ```terminal
   telemetrygen logs --logs 5 --otlp-insecure \
     --otlp-attributes http.request.method=\"GET\" \
     --otlp-attributes url.path=\"/api/users/123\" \
     --otlp-attributes http.response.status_code=200 \
     --otlp-attributes duration_ms=120
   ```

3. Send a couple of failing requests on the same route family:
   ```terminal
   telemetrygen logs --logs 2 --otlp-insecure \
     --otlp-attributes http.request.method=\"GET\" \
     --otlp-attributes url.path=\"/api/users/456\" \
     --otlp-attributes http.response.status_code=500 \
     --otlp-attributes duration_ms=900
   ```

4. Watch the Collector's console:
   - the metrics pipeline emits `http.server.request.duration` exponential-histogram
     datapoints for route `/api/users/{id}` — one for `http.response.status_code=200`
     (count 5), another for `http.response.status_code=500` (count 2). The two raw paths
     (`/api/users/123`, `/api/users/456`) collapse into the same `http.route`.
   - the logs pipeline only prints the 2 `500` records; the 5 `200` bodies never appear as
     logs.

## 🎯 Key details

- The `transform` processor derives `http.route` from `url.path`: it strips the query
  string and collapses numeric path segments to `{id}` — this is what bounds the metric's
  cardinality.
- `telemetrygen`'s `--otlp-attributes` can't send floating-point values, so the recipe
  sends an integer `duration_ms` and casts it in OTTL (`Double(...) / 1000.0`) to the
  seconds value the histogram expects.
- `signal_to_metrics` (the connector, not `count`) is what makes this a *dimensioned*
  metric: HTTP semantic conventions define only `http.server.request.duration` for
  server-side access logs, no separate request counter, because the histogram's own count
  already carries request volume, and filtering it by `http.response.status_code` gives
  the error rate.
- The `forward`/`filter` fan-out mirrors [`logs-to-metrics`](../logs-to-metrics/) and
  [`count-before-sampling`](../count-before-sampling/): one incoming pipeline is split so
  the same records can be both converted to metrics and selectively kept as logs. Here,
  `filter` drops everything below `500`, so only server errors reach `debug/logs` — a
  forensic path alongside the metric.
- `signal_to_metrics` aggregates per `Consume*` call, with no internal flush interval —
  put a `batch` processor upstream of it in production so more records fold into each
  emitted datapoint; this recipe skips it to keep the demo deterministic.
- This recipe supersedes, for the HTTP-access-log use case, the `count`-connector approach
  in [`logs-to-metrics`](../logs-to-metrics/); that recipe now links back here.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
```

- [ ] **Step 2: Commit**

```bash
git add starters/access-logs-to-metrics/README.md
git commit -m "docs: add access-logs-to-metrics recipe README"
```

---

## Task 3: Runtime smoke test

**Files:**
- None created/modified — this task only runs the recipe from Tasks 1–2 and verifies its
  documented behavior. If the config needs a fix, amend
  `starters/access-logs-to-metrics/otelcol.yaml` in this task and re-run.

**Interfaces:**
- Consumes: `starters/access-logs-to-metrics/otelcol.yaml` (Task 1), the exact
  `telemetrygen` commands and expected output documented in
  `starters/access-logs-to-metrics/README.md` (Task 2).

- [ ] **Step 1: Start the Collector via Docker**

```bash
docker run -d --name access-logs-to-metrics-smoketest \
  -p 4317:4317 \
  -v "$(pwd)/starters/access-logs-to-metrics/otelcol.yaml:/etc/otelcol-contrib/config.yaml" \
  otel/opentelemetry-collector-contrib:0.155.0
```

Expected: prints a container ID, no immediate exit. Confirm with:

```bash
sleep 2 && docker ps --filter name=access-logs-to-metrics-smoketest --format '{{.Status}}'
```

Expected: a line starting with `Up`.

- [ ] **Step 2: Send the successful-request batch**

```bash
docker run --rm ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.155.0 \
  logs --logs 5 --otlp-insecure --otlp-endpoint host.docker.internal:4317 \
  --otlp-attributes 'http.request.method="GET"' \
  --otlp-attributes 'url.path="/api/users/123"' \
  --otlp-attributes http.response.status_code=200 \
  --otlp-attributes duration_ms=120
```

Expected: exits 0, no error output.

- [ ] **Step 3: Send the failing-request batch**

```bash
docker run --rm ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.155.0 \
  logs --logs 2 --otlp-insecure --otlp-endpoint host.docker.internal:4317 \
  --otlp-attributes 'http.request.method="GET"' \
  --otlp-attributes 'url.path="/api/users/456"' \
  --otlp-attributes http.response.status_code=500 \
  --otlp-attributes duration_ms=900
```

Expected: exits 0, no error output.

- [ ] **Step 4: Inspect the Collector logs and verify the documented behavior**

```bash
docker logs access-logs-to-metrics-smoketest 2>&1 | grep -A 20 "Metric #0"
docker logs access-logs-to-metrics-smoketest 2>&1 | grep -B2 -A5 "Body: Str"
```

Expected (allow for exact formatting differences in the `debug` exporter's dump):
- A `http.server.request.duration` exponential-histogram metric appears twice: once with
  `http.response.status_code(int): 200`, count `5`, and once with
  `http.response.status_code(int): 500`, count `2`. Both carry
  `http.route(str): /api/users/{id}` (not the raw `/api/users/123` / `/api/users/456`) and
  `http.request.method(str): GET`.
- Exactly 2 log records are printed by the `debug/logs` exporter (the `500`s); the `200`
  bodies do not appear in the logs output.

If the output doesn't match — e.g. `http.route` still shows the raw numeric id, or all 7
records appear as logs — fix `starters/access-logs-to-metrics/otelcol.yaml` (most likely
culprits: the `replace_pattern` regex, or the `filter/keep-errors` condition polarity) and
repeat from Step 1 after removing the old container (`docker rm -f
access-logs-to-metrics-smoketest`).

- [ ] **Step 5: Tear down**

```bash
docker rm -f access-logs-to-metrics-smoketest
```

- [ ] **Step 6: Commit any fixes made during this task**

If Step 4 required changes to `otelcol.yaml`:

```bash
git add starters/access-logs-to-metrics/otelcol.yaml
git commit -m "fix: correct access-logs-to-metrics config after smoke test"
```

If no changes were needed, skip this step — there is nothing to commit.

---

## Task 4: Deprecate `logs-to-metrics` for the access-log use case

**Files:**
- Modify: `starters/logs-to-metrics/README.md`

**Interfaces:**
- Consumes: the path `../access-logs-to-metrics/`, valid after Task 2.

- [ ] **Step 1: Add the deprecation callout**

In `starters/logs-to-metrics/README.md`, immediately below the title line (`# 🍜 Recipe:
Logs to Metrics`) and above the description paragraph, insert:

```markdown

> ⚠️ **Deprecated for HTTP access logs.** For converting HTTP access logs to metrics, see
> [`access-logs-to-metrics`](../access-logs-to-metrics/) instead, which uses semantic
> convention attribute names and the `signal_to_metrics` connector. This recipe remains a
> minimal example of counting arbitrary discrete log events with the `count` connector.
```

Do not change any other content in this file — the config, the rest of the README, and its
own "Tested with" pins stay as-is.

- [ ] **Step 2: Verify the file renders sensibly**

Run: `head -n 10 starters/logs-to-metrics/README.md`
Expected: title line, blank line, the new blockquote callout, blank line, then the
original description paragraph ("High-volume, low-information log lines...").

- [ ] **Step 3: Commit**

```bash
git add starters/logs-to-metrics/README.md
git commit -m "docs: deprecate logs-to-metrics for the HTTP access-log use case"
```

---

## Task 5: Add the new recipe to the top-level index

**Files:**
- Modify: `README.md:32` (the row immediately after `logs-to-metrics` in the Index table)

**Interfaces:**
- Consumes: the path `starters/access-logs-to-metrics/`, valid after Task 1.

- [ ] **Step 1: Insert the new index row**

In `README.md`, immediately after the `logs-to-metrics` row (currently line 32), add:

```markdown
| [access-logs-to-metrics](starters/access-logs-to-metrics/) | starters | logs → logs + metrics | local | signaltometricsconnector, transformprocessor |
```

This matches the index table's existing legacy-suffix naming style for the "Key
components" column (e.g. `countconnector`, `filterprocessor` on neighboring rows) — do not
rename any other row.

- [ ] **Step 2: Verify the table still renders as valid Markdown**

Run: `grep -n "access-logs-to-metrics" README.md`
Expected: one match, the new row, positioned between the `logs-to-metrics` and `tls` rows.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: list access-logs-to-metrics in the recipe index"
```
