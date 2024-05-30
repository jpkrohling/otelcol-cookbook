# 🍜 Recipe: Client-side load balancing

This recipe shows how to configure a Collector to load balance its exporter requests to another layer of Collectors. While the solution itself is very simple, comprising of two lines of configuration, verifying that it works is trickier: we want to start with a fixed number of server instances, likely higher than 1, and scale up. If it works, we'll see that all instances will have equivalent load over time, with the rate of requests going down as more server collectors are available. 

For a successful load-balancing, we need clients that are able to retrieve a list of available endpoints, and we need the server to force connections to be closed at a specific amount of time. While the client configuration can be reused as is, the server configuration in this example requires some attention before being used in production: make sure to adjust the max connection age to a value that makes sense to you.

We are discarding the telemetry data that we are generating, as we are only interested in assessing this behavior by observing the Collector's own metrics.

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol-client.yaml` file from this directory
- The `otelcol-server.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns client-side-load-balancing
    kubens client-side-load-balancing
   ```

2. Generate a basic auth HTTP header
   ```terminal
   echo -n "$GRAFANA_CLOUD_USER:$GRAFANA_CLOUD_TOKEN" | base64 -w0
   ```

3. Use the output from the command above as the value for the basic auth header on `otelcol-server.yaml`

4. Change the `endpoint` parameter for the `otlp` exporter within the `telemetry` node on `otelcol-server.yaml` to point to your stack's endpoint, plus the path `/v1/traces`

5. Install the OTel Collector server custom resource
   ```terminal
   kubectl apply -f otelcol-server.yaml
   ```

6. Install the OTel Collector client custom resource
   ```terminal
   kubectl apply -f otelcol-client.yaml
   ```

7. Open a port-forward to the client Collector: 
   ```terminal
   kubectl port-forward svc/otelcol-client-collector 4317
   ```

8. Send 100 traces per second to the client collector for 10 minutes, so that we can see the effects of our changes 
   ```terminal
   telemetrygen traces --rate 100 --duration 10m --otlp-insecure --otlp-attributes='recipe="client-side-load-balancing"'
   ```

9. After a few minutes, update the `otelcol-server.yaml` to have 10 replicas instead of the original 5.

10. Open your Grafana instance, go to Explore, and select the metrics datasource ("...-prom") and a run a query like: `rate(receiver_accepted_spans_total[$__rate_interval])`. You can also remove the `rate` function to see the totals, which should show the first collectors having similar numbers among themselves, while the newer collectors would have lower numbers, but still equivalent among each other.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.100.1
- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
