# Log Clustering Recipe Design

## Summary

Add a new `starters/` recipe demonstrating the `drain` processor: it clusters
similar log lines and attaches a derived template string (e.g.
`"user <*> logged in from <*>"`) as the `log.record.template` attribute.

## Location

`starters/log-clustering/`
- `otelcol.yaml`
- `README.md`

Chosen over `mains/` because this is a single-concept, local-only
demonstration — no Kubernetes, no persistence, no seeding/warmup tuning.
Mirrors the depth of `starters/log-deduplication`.

## Pipeline

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
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

Defaults only — no tuning of `tree_depth`, `merge_threshold`, etc. The point
is to show the mechanism, not tune it.

## Demo flow

`telemetrygen logs --body` sends one fixed string per invocation, so varying
tokens (user name, IP) requires separate invocations rather than one batch
run:

1. Start the collector with the recipe config.
2. Run `telemetrygen logs` three times, once each with:
   - `"user alice logged in from 10.0.0.1"`
   - `"user bob logged in from 10.0.0.2"`
   - `"user carol logged in from 10.0.0.3"`
3. Run `telemetrygen logs` once more with a differently-shaped line:
   - `"connected to 10.0.0.9"`
4. Point at the `debug` exporter console output: the three login lines carry
   `log.record.template: "user <*> logged in from <*>"`, while the fourth
   carries its own distinct template — showing the clustering converges per
   log shape rather than per literal string.

## README content (Key details section)

- Brief explanation of how Drain builds a parse tree and derives templates
  (tokenize, cluster by similarity, replace variable tokens with `<*>`).
- Note that the processor **annotates only** — pair with a `filter` processor
  downstream to act on `log.record.template` (e.g. drop known-noisy
  patterns), referencing the drain processor's own example pipeline upstream.
- Pointers (not wired into the config) to `seed_templates`/`seed_logs` for
  stable templates across restarts, `warmup_min_clusters` to suppress
  annotation until the tree stabilizes, and `storage`/`save_interval` for
  snapshot persistence — flagged explicitly as production concerns out of
  scope for this minimal recipe.

## Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0

(Matches current pins in `CLAUDE.md`.)

## Validation

Smoke test per `CLAUDE.md`: run the collector via the contrib Docker image,
drive the four `telemetrygen` invocations above, and confirm the debug
exporter output shows the expected template attribute values before
considering the recipe done.
