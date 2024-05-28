# 🍜 Recipe: Profiling the Collector

This recipe shows how to use Pyroscope to profile the OpenTelemetry Collector running on a Kubernetes cluster. It's recommended to take a look first at the following recipes before using this one:

- ["grafana-cloud"](../grafana-cloud/)
- ["grafana-cloud-from-kubernetes"](../grafana-cloud-from-kubernetes/)

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- Pyroscope Agent configured using Grafana Alloy
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector
- The `otelcol-cr.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_PROFILES_USER` environment variable, found under the instructions for "Pyroscope" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_PROFILES_TOKEN` environment variable, which can be generated under the instructions for "Pyroscope" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns profiling-the-collector
    kubens profiling-the-collector
   ```

2. Create a secret with the credentials:
   ```terminal
    kubectl create secret generic grafana-cloud-credentials --from-literal=GRAFANA_CLOUD_USER="$GRAFANA_CLOUD_USER" --from-literal=GRAFANA_CLOUD_TOKEN="$GRAFANA_CLOUD_TOKEN"
   ```

3. Change the `endpoint` parameter for the `otlphttp` exporter to point to your stack's endpoint

4. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f otelcol-cr.yaml
   ```

5. Open a port-forward to the Collector
   ```terminal
   kubectl port-forward svc/profiling-the-collector-collector 4317
   ```

6. Send 10 traces per second for 30 minutes to our Collector
   ```terminal
   telemetrygen traces --duration 30m --rate 10 --otlp-insecure --otlp-attributes='recipe="profiling-the-collector"'
   ```

7. Install a custom service exposing the `pprof` port
   ```terminal
   kubectl apply -f otelcol-pprof-svc.yaml
   ```

8. Add the Grafana Helm repository
   ```terminal
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   ```

9.  Replace the user, token, and URL on the values.yaml to reflect the values from your environment variables

10. Install Grafana Agent with the Pyroscope eBPF Profiler
   ```terminal
   helm install pyroscope-ebpf grafana/grafana-agent -f values.yaml --set username=$GRAFANA_CLOUD_PROFILES_USER --set password=$GRAFANA_CLOUD_PROFILES_TOKEN
   ```

11. Open your Grafana instance, go to Explore, and select the profiles datasource.


## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
