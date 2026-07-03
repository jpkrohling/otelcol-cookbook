# Log Clustering Recipe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `starters/log-clustering/`, a recipe demonstrating the `drain`
processor deriving a template string from clustered log lines.

**Architecture:** A single local `otelcol.yaml` (`otlp` receiver → `drain`
processor with defaults → `debug` exporter) plus a `README.md` following the
repo's recipe contract. No code, no tests in the traditional sense — recipes
are validated with a runtime smoke test (Docker collector image +
`telemetrygen`), per `CLAUDE.md`.

**Tech Stack:** OpenTelemetry Collector Contrib (Docker image
`otel/opentelemetry-collector-contrib:0.154.0`), `telemetrygen` (Docker image
`ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.154.0`).

## Global Constraints

- Config files are always `.yaml`, never `.yml`.
- Use current, non-deprecated component names (`drain`, not any alias).
- README must follow the 7-section recipe contract from `CLAUDE.md`
  (Title, Description, Metadata table, Ingredients, Preparation, optional Key
  details, Tested with).
- Pinned versions for this recipe: OpenTelemetry Collector Contrib v0.154.0,
  `telemetrygen` v0.154.0 (per `CLAUDE.md`'s Version Compatibility section).
- Each recovered/added recipe must pass a runtime smoke test before it's
  considered done.

---

### Task 1: Create the recipe config

**Files:**
- Create: `starters/log-clustering/otelcol.yaml`

**Interfaces:**
- Produces: a collector config listening on `0.0.0.0:4317` (OTLP gRPC),
  running the `drain` processor with default settings, exporting to `debug`
  with `verbosity: detailed`. Task 3's smoke test depends on this exact
  endpoint and exporter verbosity.

- [ ] **Step 1: Write the config file**

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  # Clusters similar log lines and derives a template string (e.g.
  # "user <*> logged in from <*>"), attaching it as the `log.record.template`
  # attribute. Defaults are used here; see README for tuning notes.
  drain: {}

exporters:
  debug:
    verbosity: detailed

service:
  pipelines:
    logs:
      receivers: [otlp]
      processors: [drain]
      exporters: [debug]
```

- [ ] **Step 2: Validate the YAML parses**

Run: `docker run --rm -v "$(pwd)/starters/log-clustering/otelcol.yaml:/cfg.yaml" otel/opentelemetry-collector-contrib:0.154.0 validate --config=/cfg.yaml`
Expected: exits 0, no error output. If `drain` is reported as an unknown
component, note the failure — this pinned image build may not include it —
and stop here to report the discrepancy before continuing (do not silently
switch to an unpinned/newer tag).

- [ ] **Step 3: Commit**

```bash
git add starters/log-clustering/otelcol.yaml
git commit -m "$(cat <<'EOF'
feat: add starters/log-clustering otelcol.yaml (drain processor)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01YXRooGMaMKeAa9B3FJXt3y
EOF
)"
```

---

### Task 2: Write the recipe README

**Files:**
- Create: `starters/log-clustering/README.md`

**Interfaces:**
- Consumes: the exact pipeline from Task 1 (`otlp` receiver on `4317`, `drain`
  processor with defaults, `debug` exporter at `verbosity: detailed`).
- Produces: the full recipe documentation, including the exact
  `telemetrygen` commands Task 3's smoke test will run verbatim.

- [ ] **Step 1: Write the README**

```markdown
# 🍜 Recipe: Log Clustering

Similar log lines often differ only in a few variable tokens — a username, an
IP address, a request ID. The `drain` processor clusters log lines by their
structural shape and derives a template string (e.g.
`"user <*> logged in from <*>"`), attaching it as the `log.record.template`
attribute so downstream processors and backends can group, filter, or count by
pattern instead of by literal message.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | drainprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/log-clustering/otelcol.yaml
   ```

2. Send three login-style logs that share the same shape but differ in the
   username and IP address:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "user alice logged in from 10.0.0.1"
   telemetrygen logs --otlp-insecure --logs 1 --body "user bob logged in from 10.0.0.2"
   telemetrygen logs --otlp-insecure --logs 1 --body "user carol logged in from 10.0.0.3"
   ```

3. Send one differently-shaped log line:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "connected to 10.0.0.9"
   ```

4. Watch the Collector's console. The three login lines each carry the same
   derived template, despite the different names and addresses:
   ```
        -> log.record.template: Str(user <*> logged in from <*>)
   ```
   The fourth line, being a different shape, gets its own template:
   ```
        -> log.record.template: Str(connected to <*>)
   ```

## 🎯 Key details

- Drain builds a parse tree from the token structure of each log line. Lines
  with similar structure are grouped into a cluster, and the template is
  derived by replacing variable tokens with `<*>`. Templates become more
  accurate and stable as more logs matching a pattern arrive.
- This processor **annotates**; it does not filter. Pair it with a `filter`
  processor downstream to act on `log.record.template` — for example, to drop
  known-noisy patterns like health checks or heartbeats.
- For stable templates across restarts or scaled deployments, the processor
  supports `seed_templates`/`seed_logs` (pre-train known patterns at startup),
  `warmup_min_clusters` (suppress annotation until the tree stabilizes), and
  `storage`/`save_interval` (persist the tree via a storage extension). These
  are production concerns not wired up in this minimal recipe — see the
  `drain` processor's own README for details.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
```

- [ ] **Step 2: Commit**

```bash
git add starters/log-clustering/README.md
git commit -m "$(cat <<'EOF'
docs: add starters/log-clustering README

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01YXRooGMaMKeAa9B3FJXt3y
EOF
)"
```

---

### Task 3: Runtime smoke test

**Files:**
- None created/modified unless the smoke test surfaces a problem, in which
  case fix `starters/log-clustering/otelcol.yaml` and/or
  `starters/log-clustering/README.md` from Tasks 1–2 and recommit.

**Interfaces:**
- Consumes: the config from Task 1 and the exact `telemetrygen` commands from
  Task 2, Step 1.

- [ ] **Step 1: Start the collector container**

```bash
docker run -d --name log-clustering-smoke \
  -p 4317:4317 \
  -v "$(pwd)/starters/log-clustering/otelcol.yaml:/etc/otelcol-contrib/config.yaml" \
  otel/opentelemetry-collector-contrib:0.154.0
```

Expected: container starts and stays running.
Run: `docker ps --filter name=log-clustering-smoke`
Expected: one row, `STATUS` showing `Up ...`.

- [ ] **Step 2: Check startup logs for errors**

Run: `docker logs log-clustering-smoke`
Expected: no fatal errors; the `drain` processor is listed among the started
components. If `drain` is not recognized by this image build, stop and report
this — do not swap to an unpinned image tag to make it work.

- [ ] **Step 3: Send the four log lines from the README**

```bash
docker run --rm --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.154.0 \
  logs --otlp-insecure --otlp-endpoint host.docker.internal:4317 --logs 1 \
  --body "user alice logged in from 10.0.0.1"

docker run --rm --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.154.0 \
  logs --otlp-insecure --otlp-endpoint host.docker.internal:4317 --logs 1 \
  --body "user bob logged in from 10.0.0.2"

docker run --rm --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.154.0 \
  logs --otlp-insecure --otlp-endpoint host.docker.internal:4317 --logs 1 \
  --body "user carol logged in from 10.0.0.3"

docker run --rm --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.154.0 \
  logs --otlp-insecure --otlp-endpoint host.docker.internal:4317 --logs 1 \
  --body "connected to 10.0.0.9"
```

Expected: each command exits 0.

- [ ] **Step 4: Verify the derived templates in the collector output**

Run: `docker logs log-clustering-smoke 2>&1 | grep -A2 "log.record.template"`
Expected: three occurrences of
`log.record.template: Str(user <*> logged in from <*>)` and one occurrence of
`log.record.template: Str(connected to <*>)`. If the wildcard placement or
attribute name differs, update `starters/log-clustering/README.md`'s Step 4
console output and, if needed, the config in Task 1 to match reality, then
recommit both.

- [ ] **Step 5: Tear down**

```bash
docker rm -f log-clustering-smoke
```

- [ ] **Step 6: Commit any fixes discovered during the smoke test**

Only run this if Step 4 required changes:

```bash
git add starters/log-clustering/otelcol.yaml starters/log-clustering/README.md
git commit -m "$(cat <<'EOF'
fix: correct starters/log-clustering after smoke test

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01YXRooGMaMKeAa9B3FJXt3y
EOF
)"
```
