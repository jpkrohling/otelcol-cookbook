# Access logs → metrics recipe — design

**Date:** 2026-07-04
**Status:** approved (brainstorming) — ready for implementation plan

## Summary

Add a new starter recipe, `starters/access-logs-to-metrics`, showing the idiomatic way to
turn high-volume HTTP access logs into metrics using semantic-convention attribute names
and the `signal_to_metrics` connector. Mark the existing `starters/logs-to-metrics` recipe
(which uses the `count` connector) as deprecated for this specific use case, pointing readers
to the new recipe.

## Background

`starters/logs-to-metrics` demonstrates the `count` connector: it turns a stream of
matching log records into a single counter metric (`log.record.count`). That's a fine
minimal example of "count discrete events," but it doesn't reflect how real HTTP access
logs (nginx, Kong, envoy, apache) should be converted: their value isn't just a count, it's
rate/errors/latency **by route**, and the `signal_to_metrics` connector (not `count`) is the
current component for deriving dimensioned metrics — including histograms — from logs.

The new recipe should:
- Use OTel HTTP semantic convention attribute names throughout (`http.request.method`,
  `url.path`, `http.response.status_code`, `http.route`), consistent with this repo's
  existing testing-pattern convention (see CLAUDE.md).
- Normalize the raw URL into a low-cardinality `http.route` before it becomes a metric
  dimension.
- Emit the metric semconv recommends for HTTP server access logs:
  `http.server.request.duration` (histogram). HTTP semconv defines no separate request
  counter — the histogram's own count carries request volume, and status-filtered count
  gives the error rate.
- Keep a forensic path: 5xx access logs are also retained as logs (not just converted),
  demonstrating a realistic dual-pipeline rollout instead of destroying error-level detail.

## Non-goals

- Replacing `starters/count-before-sampling` (different use case: counting trace volume
  before tail sampling — unaffected).
- Deleting `starters/logs-to-metrics` — it remains valid as a minimal "count discrete log
  events" example; only its README gains a deprecation note scoped to the access-log
  use case.
- Production-grade batching/tuning guidance beyond a short callout (see Key details below).

## Recipe: `starters/access-logs-to-metrics`

| | |
|---|---|
| **Signals** | logs → logs + metrics |
| **Runs on** | local binary |
| **Key components** | `transform`, `signal_to_metrics`, `forward`, `filter` |

### Pipeline

1. **Receive**: `otlp` receiver, as in every other starter recipe.
2. **`transform/access-log-route`** (OTTL, `log` context): derive `http.route` from
   `url.path` — strip the query string, collapse numeric path segments to `{id}` — and
   cast the raw `duration_ms` attribute (an integer, since `telemetrygen`'s
   `--otlp-attributes` doesn't support floats) to a `double` seconds value for the
   histogram.
3. **`forward`** fans the transformed stream to two pipelines:
   - **all records** → `signal_to_metrics`, emitting `http.server.request.duration`
     (exponential histogram, unit `s`), dimensioned by `http.request.method`,
     `http.response.status_code`, `http.route`.
   - **5xx only**, via `filter` keeping `http.response.status_code >= 500` → `debug/logs`,
     the forensic path. 2xx/3xx/4xx bodies never reach a logs exporter.
4. **Exporters**: `debug/logs` and `debug/metrics` (matching the existing recipes' style —
   no LGTM stack dependency for a starter).

### Test data (telemetrygen)

Send a mix of successful and failing requests, each carrying access-log-shaped attributes:

```
telemetrygen logs --logs 5 --otlp-insecure \
  --otlp-attributes http.request.method=\"GET\" \
  --otlp-attributes url.path=\"/api/users/123\" \
  --otlp-attributes http.response.status_code=200 \
  --otlp-attributes duration_ms=120

telemetrygen logs --logs 2 --otlp-insecure \
  --otlp-attributes http.request.method=\"GET\" \
  --otlp-attributes url.path=\"/api/users/456\" \
  --otlp-attributes http.response.status_code=500 \
  --otlp-attributes duration_ms=900
```

Expected collector output:
- the metrics pipeline emits one `http.server.request.duration` series for
  `GET /api/users/{id}` × `200`, and another for `GET /api/users/{id}` × `500` — the two raw
  paths (`/api/users/123`, `/api/users/456`) collapse into one route dimension;
- the logs pipeline shows only the 2 `500` records; the 5 `200` bodies never appear as logs.

### Key details (planned content)

- Why aggregate beats per-record logs for access logs: value is rate/errors/latency by
  route, at a fraction of the log volume.
- Route normalization rules and why they bound cardinality (strip query string, collapse
  numeric ids to `{id}`).
- Why only a duration histogram is emitted, not a separate request counter — HTTP semconv
  defines none; the histogram's count already carries volume.
- `signal_to_metrics` is Alpha stability and aggregates per `Consume*` call with no internal
  flush interval — a brief callout that production use needs batching upstream for
  reasonable datapoint volume, without expanding the demo's scope.
- The `forward`/`filter` fan-out mirrors the pattern already used in
  `logs-to-metrics`/`count-before-sampling`, but here it also demonstrates the
  metrics-plus-forensic-errors rollout shape recommended for real access-log migrations.

## Deprecating `starters/logs-to-metrics`

Add a short callout near the top of its README (below the title, above the metadata
table):

> ⚠️ **Deprecated for HTTP access logs.** For converting HTTP access logs to metrics,
> see [`access-logs-to-metrics`](../access-logs-to-metrics/) instead, which uses semantic
> convention attribute names and the `signal_to_metrics` connector. This recipe remains a
> minimal example of counting arbitrary discrete log events with the `count` connector.

No other content changes — the recipe, its config, and its own tested-with pins stay as-is.

## Testing

Both recipes get a runtime smoke test per this repo's contract: local recipe via the
`otelcol-contrib` binary + `telemetrygen`, verifying the described collector output.

## Version pins

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0

(matching current repo-wide pins in CLAUDE.md)
