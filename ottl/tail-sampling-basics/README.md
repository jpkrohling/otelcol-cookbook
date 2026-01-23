# Recipe: Tail Sampling Basics

This recipe demonstrates how to use the tail sampling processor to keep only traces that matter for debugging: errors and slow requests. Fast, successful traces are dropped, reducing storage costs while maintaining full observability for incidents.

Unlike head sampling, tail sampling evaluates the complete trace before making a decision, so you never accidentally drop an error.

## Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `config.yaml` file from this directory
- The `telemetrygen` tool, or any other application that can send OTLP traces to the collector

## Preparation

1. Start the Collector Contrib binary using the provided configuration
   ```terminal
   otelcol-contrib --config ottl/tail-sampling-basics/config.yaml
   ```

2. Send fast, successful traces (these should be dropped)
   ```terminal
   telemetrygen traces \
     --otlp-insecure \
     --traces 5 \
     --telemetry-attributes http.status_code=200
   ```

3. Send error traces (these should be kept)
   ```terminal
   telemetrygen traces \
     --otlp-insecure \
     --traces 2 \
     --status-code Error \
     --telemetry-attributes http.status_code=500
   ```

4. Send slow traces (these should be kept)
   ```terminal
   telemetrygen traces \
     --otlp-insecure \
     --traces 2 \
     --span-duration 600ms \
     --telemetry-attributes http.status_code=200
   ```

5. Watch the collector's output. After the `decision_wait` period (10s), you should see only:
   - Traces with `Status code: Error`
   - Traces with duration > 500ms
   
   The fast, successful traces from step 2 should not appear.

## How it works

The tail sampling processor holds traces in memory for the `decision_wait` period, allowing all spans to arrive before making a sampling decision.

Two policies are configured with OR logic (any match = keep):

- **errors**: Keeps any trace where at least one span has `status.code = ERROR`
- **slow-requests**: Keeps any trace where at least one span takes longer than 500ms

```yaml
policies:
  - name: errors
    type: status_code
    status_code:
      status_codes: [ERROR]
  - name: slow-requests
    type: latency
    latency:
      threshold_ms: 500
```

## Key configuration options

- `decision_wait`: How long to wait for spans before deciding (default: 30s)
- `num_traces`: Maximum traces to hold in memory (default: 50000)
- `expected_new_traces_per_sec`: Helps size internal data structures

## Extending the recipe

Add more policies to capture other interesting traces:

```yaml
policies:
  - name: errors
    type: status_code
    status_code:
      status_codes: [ERROR]
  - name: slow-requests
    type: latency
    latency:
      threshold_ms: 500
  - name: specific-service
    type: string_attribute
    string_attribute:
      key: service.name
      values: [payment-service, checkout-service]
  - name: baseline
    type: probabilistic
    probabilistic:
      sampling_percentage: 1
```

## Executed last time with these versions

- OpenTelemetry Collector Contrib v0.143.1
- telemetrygen v0.143.1
