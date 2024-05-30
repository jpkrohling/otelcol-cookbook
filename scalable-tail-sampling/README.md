# 🍜 Recipe: Scalable tail sampling

This recipe shows how to prepare a scalable tail sampling pipeline. Tail sampling is a strategy that allows the decision to be made after a trace has had enough time to be completed, and has the ability to use trace-based information to determine whether the trace interesting or not. Because traces are kept in memory, we use a trace ID aware load balancer to consistently route spans belonging to the same trace to the same backing collectors. We have therefore two layers of collectors: one doing the load-balancing, and one doing the sampling.

We are discarding the telemetry data that we are generating, as we are only interested in assessing this behavior by observing the Collector's metrics.

**Note:** at this moment, not all metrics are being exported from the Collector using the new OpenTelemetry Metrics exporter. Until that is done, you might want to remove the `telemetry` section of the configuration files and scrape those metrics using a Prometheus-compatible scraper (like another OTel Collector instance with the Prometheus receiver).

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector
- The `otelcol-load-balancer.yaml` file from this directory
- The `otelcol-sampling.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns scalable-tail-sampling
    kubens scalable-tail-sampling
   ```

1. Generate a basic auth HTTP header
   ```terminal
   echo -n "$GRAFANA_CLOUD_USER:$GRAFANA_CLOUD_TOKEN" | base64 -w0
   ```

2. Use the output from the command above as the value for the basic auth header on both `otelcol-sampling.yaml` and `otelcol-loadbalancer.yaml`

3. On the same files, change the `endpoint` parameter for the `otlp` exporter within the `telemetry` node to point to your stack's endpoint, plus the path `/v1/traces`

4. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f otelcol-sampling.yaml
   kubectl apply -f otelcol-loadbalancer.yaml
   ```

5. Open a port-forward to the Collector:
   ```terminal
   kubectl port-forward svc/otelcol-loadbalancer-collector 4317
   ```

6. Send some telemetry to your Collector: those should all be sampled, given that they belong to VIP customers
   ```terminal
   telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --otlp-attributes='vip="true"'
   ```

7. Open your Grafana instance, go to Explore, select the metrics datasource, and verify how many spans have been received by the load balancer instances by running the following query: `receiver_accepted_spans_total{job="otelcol-loadbalancer"}`

8. Send some more telemetry to your Collector: only 10% of those should be sampled, as they are not from VIP customers
   ```terminal
   telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --otlp-attributes='vip="false"'
   ```

9. Verify how many spans have been received by the sampling instances by running the following query: `receiver_accepted_spans_total{job="otelcol-sampling"}`


## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.100.1
- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
