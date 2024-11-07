# 🍜 Recipe: Auto-instrumentation

TODO

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- A non-instrumented application written in a language that has auto-instrumentation support, such as Keycloak (Java)
- The `otelcol-cr.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns auto-instrumentation
    kubens auto-instrumentation
   ```

2. Create a secret with the credentials: 
   ```terminal
    kubectl create secret generic grafana-cloud-credentials --from-literal=GRAFANA_CLOUD_USER="$GRAFANA_CLOUD_USER" --from-literal=GRAFANA_CLOUD_TOKEN="$GRAFANA_CLOUD_TOKEN"
   ```

3. Change the `endpoint` parameter for the `otlphttp` exporter to point to your stack's endpoint
   
4. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f auto-instrumentation/otelcol-cr.yaml
   ```

5. Install the application to be instrumented, like Keycloak
   ```terminal
   kubectl apply -f auto-instrumentation/keycloak.yaml
   ```

6. Play with the application, so that it generates telemetry
   ```terminal
   kubectl port-forward svc/keycloak 8080
   ```

7. Open your Grafana instance, go to Explore, and select the appropriate datasource, such as "...-traces". If used the command above, click "Search" and you should see two traces listed, each with two spans.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.100.1
- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
