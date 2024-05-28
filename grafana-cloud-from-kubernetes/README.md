# 🍜 Recipe: Grafana Cloud from Kubernetes

This recipe shows how to send telemetry data to Grafana Cloud with the OpenTelemetry Collector running on a Kubernetes Cluster. This is very similar to the ["grafana-cloud"](../grafana-cloud/) recipe, with extra steps to make it run on Kubernetes. You are encouraged to try that one first if you are not familiar with the Collector or sending data to Grafana Cloud via OTLP.

One interesting aspect of this recipe is that it keeps the credentials on a secret, mounting them as environment variables. This way, the secrets aren't exposed in plain-text.

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol-cr.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns grafana-cloud-from-kubernetes
    kubens grafana-cloud-from-kubernetes
   ```

2. Create a secret with the credentials: 
   ```terminal
    kubectl create secret generic grafana-cloud-credentials --from-literal=GRAFANA_CLOUD_USER="..." --from-literal=GRAFANA_CLOUD_TOKEN="..."
   ```

3. Change the `endpoint` parameter for the `otlphttp` exporter to point to your stack's endpoint
   
4. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f grafana-cloud-from-kubernetes/otelcol-cr.yaml
   ```

5. Open a port-forward to the Collector: 
   ```terminal
   kubectl port-forward svc/grafana-cloud-from-kubernetes-collector 4317
   ```

6. Send some telemetry to your Collector
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="grafana-cloud-from-kubernetes"'
   ```

7. Open your Grafana instance, go to Explore, and select the appropriate datasource, such as "...-traces". If used the command above, click "Search" and you should see two traces listed, each with two spans.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.100.1
- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
