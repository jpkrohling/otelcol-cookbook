# 🍮 Recipe: Tail-Sampling Tasting Menu

A guided tour of the `tail_sampling` processor's policy types, plated as one realistic strategy: keep every error, keep every slow trace, keep everything flagged important, and keep a 10% baseline of everything else. The à la carte menu in [🎯 Key details](#-key-details) covers every policy type and how to compose them.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | tailsamplingprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- Docker, to run the LGTM backend
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start LGTM so the Collector can export its own metrics over OTLP:
   ```terminal
   docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm:0.30.2
   ```

2. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config desserts/tail-sampling-tasting-menu/otelcol.yaml
   ```

3. Send one batch per course, each tagged so a single policy decides it:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 20 --status-code Error          # errors
   telemetrygen traces --otlp-insecure --traces 20 --span-duration 2s           # slow
   telemetrygen traces --otlp-insecure --traces 20 --telemetry-attributes vip=\"true\"  # vip
   telemetrygen traces --otlp-insecure --traces 100                             # normal traffic
   ```

4. Open Grafana at `http://localhost:3000`, go to **Explore**, select the Prometheus data source,
   and query the processor's own decision metrics after the periodic export completes:
   ```promql
   otelcol_processor_tail_sampling_count_traces_sampled_total{service_name="otelcol-tail-sampling-tasting-menu"}
   ```
   The `errors`, `slow`, and `vip` policies each report `sampled="true"` for all 20 of their
   traces (100% kept), while `baseline` keeps roughly 10% of the normal traffic. A trace that
   matches none of the first three but wins the 10% baseline still gets kept — policies are OR'd.

## 🎯 Key details

A trace is **kept if *any* top-level policy votes to sample it** (logical OR). Order doesn't
change the outcome — a single "sample" wins. The full menu of policy types:

- **`always_sample`** — keep everything; handy to confirm the pipeline is wired up.
- **`probabilistic`** — keep `sampling_percentage`% by hashing the trace ID. It's a *chance* per
  trace, not an exact quota. (For head sampling, the standalone `probabilistic_sampler` is cheaper.)
- **`latency`** — keep traces whose duration exceeds `threshold_ms` (optionally under `upper_threshold_ms`).
- **`status_code`** — keep traces containing a span with `status_codes` in `[ERROR, OK, UNSET]`.
- **`string_attribute`** — keep traces with an attribute `key` matching `values`; add
  `invert_match: true` to keep the ones that *don't* match, or `enabled_regex_matching: true` for patterns.
- **`numeric_attribute` / `boolean_attribute`** — the same idea for integer-range and true/false attributes.
- **`rate_limiting`** — cap kept spans at `spans_per_second`, a blunt volume ceiling.
- **`ottl_condition`** — keep traces matching an arbitrary OTTL boolean over `span` / `spanevent`
  (e.g. `attributes["http.route"] == "/checkout"`), the most expressive option.

Composing them:

- **`and`** — wrap an `and_sub_policy` list so **all** sub-policies must agree before a trace is
  kept (intersection), e.g. "VIP **and** 10%" downsamples even VIPs to 10%.
- **`composite`** — allocate a total rate budget across several policies by priority.

A common real-world strategy — *2% of successful calls to one busy endpoint, 100% of everything
else* — combines `and` + `ottl_condition` + `probabilistic`:

```yaml
- name: sample-2-percent-of-successful-checkout
  type: and
  and:
    and_sub_policy:
      - name: successful-checkout
        type: ottl_condition
        ottl_condition:
          span: ['attributes["http.response.status_code"] == 200 and attributes["http.route"] == "/checkout"']
      - name: two-percent
        type: probabilistic
        probabilistic: { sampling_percentage: 2 }
- name: everything-else
  type: ottl_condition
  ottl_condition:
    span: ['attributes["http.route"] != "/checkout"']
```

Operational notes:

- `decision_wait` is how long spans are buffered before the verdict — set it above your expected
  trace duration so late spans are included; longer waits cost more memory (`num_traces`).
- `tail_sampling` only sees the traces that reach *one* collector instance, so to scale it you must
  pin all of a trace's spans to the same instance first — see [`mains/scalable-tail-sampling`](../../mains/scalable-tail-sampling/).
- To keep volume metrics accurate while sampling traces, count *before* the sampler — see
  [`starters/count-before-sampling`](../../starters/count-before-sampling/).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
- Grafana LGTM v0.30.2
