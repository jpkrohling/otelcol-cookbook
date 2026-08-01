# 🍜 Recipe: OTel Collector to LGTM on Kubernetes

This recipe shows how to send telemetry data to a LGTM stack with the OpenTelemetry Collector running on a Kubernetes Cluster.

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our Collector 
- The `lgtm.yaml` file from this directory
- The `otelcol-cr.yaml` file from this directory

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns lgtm
    kubens lgtm
   ```

2. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f sides/lgtm/lgtm.yaml
   kubectl apply -f sides/lgtm/otelcol-cr.yaml
   ```

3. Open a port-forward to the Collector: 
   ```terminal
   kubectl port-forward svc/otelcol-to-lgtm-collector 4317
   ```

4. Send some telemetry to your Collector
   ```terminal
   telemetrygen traces --otlp-insecure --otlp-attributes='recipe="otelcol-to-lgtm"'
   ```

5. Open a port-forward to Grafana:
   ```terminal
   kubectl port-forward -n lgtm svc/lgtm 3000
   ```

6. Open Grafana, go to Explore, and check the traces available there.


## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- `telemetrygen` v0.157.0
- OpenTelemetry Operator v0.156.0
- OpenTelemetry Collector Contrib v0.157.0
