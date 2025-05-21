# 🍜 Recipe: Scalable tail sampling

This recipe shows how to prepare a scalable tail sampling pipeline. Tail sampling is a strategy that allows the decision to be made after a trace has had enough time to be completed, and has the ability to use trace-based information to determine whether the trace is interesting or not. Because traces are kept in memory, we use a trace ID aware load balancer to consistently route spans belonging to the same trace to the same backing collectors. We have therefore two layers of collectors: one doing the load-balancing, and one doing the sampling.

We are discarding the telemetry data that we are generating, as we are only interested in assessing this behavior by observing the Collector's metrics.

**Note:** at this moment, not all metrics are being exported from the Collector using the new OpenTelemetry Metrics exporter. Until that is done, you might want to remove the `telemetry` section of the configuration files and scrape those metrics using a Prometheus-compatible scraper (like another OTel Collector instance with the Prometheus receiver).

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- The LGTM stack running in the `lgtm` namespace. See [the LGTM directory](../_drawer/lgtm) for more details.
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector
- The `otelcol-load-balancer.yaml` file from this directory
- The `otelcol-sampling.yaml` file from this directory

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns scalable-tail-sampling
    kubens scalable-tail-sampling
   ```

2. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f scalable-tail-sampling/otelcol-sampling-0.yaml
   kubectl apply -f scalable-tail-sampling/otelcol-loadbalancer.yaml
   ```

3. Open a port-forward to the Collector:
   ```terminal
   kubectl port-forward svc/otelcol-loadbalancer-collector 4317
   ```

4. Send some telemetry to your Collector: all of them should be selected, given that all requests belong to VIPs.
   ```terminal
   telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --telemetry-attributes='vip="true"'
   ```

5. Open your Grafana instance, go to Explore, select the metrics datasource, and explore the metrics from the Collector instances. For instance:
   * `sum(otelcol_exporter_sent_spans_total{job="otelcol-loadbalancer", exporter="loadbalancing"})` -- this is the sum of all spans that were exported by the load-balancers. It's also worth checking the other `exporter` values, to understand how the load-balancer distributed the traffic to the sampling collector instances (`otelcol_exporter_sent_spans_total{job="otelcol-loadbalancer"}`).
   * `sum(otelcol_receiver_accepted_spans_total{job="otelcol-sampling", receiver="otlp"})` -- this is the sum of all spans _received_ by the sampling collectors. It should match the number above.
   * `sum(otelcol_exporter_sent_spans_total{job="otelcol-sampling", exporter="otlp"})` -- this is the sum of all spans exported by the sampling collectors. This should also match the numbers above.

6. Send some more telemetry to your Collector: only 10% should be selected, given that none are from VIPs.
   ```terminal
   telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --telemetry-attributes='vip="false"'
   ```

7. Run the same queries again. This time, the final one should be different: only ~10% of the new traces should have been selected. The following query brings a summary, where you can see that 100% of the VIP traces were sampled, while only about 10% were sampled by the other policy: `sum by (policy, sampled) (otelcol_processor_tail_sampling_count_traces_sampled_total)`

8. Deploy the alternative sampling layer, and see the difference: now, only 10% of the VIP requests are selected, while none of the non-VIP requests are selected.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.125.0
- OpenTelemetry Collector Contrib v0.126.0
- `telemetrygen` v0.126.0
