# 🍜 Recipe: Auto-instrumentation

This recipe demonstrates how to automatically instrument applications using the OpenTelemetry Operator's auto-instrumentation feature. Instead of manually adding instrumentation code to your application, this approach allows you to inject the necessary OpenTelemetry libraries and configuration at runtime. This is particularly useful for applications that you can't modify directly or when you want to quickly add observability to existing services.

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- The LGTM stack running in the `lgtm` namespace. See [the LGTM directory](../_drawer/lgtm) for more details.
- A non-instrumented application written in a language that has auto-instrumentation support, such as Keycloak (Java)
- The `otelcol-cr.yaml` file from this directory

## 🥣 Preparation

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns auto-instrumentation
    kubens auto-instrumentation
   ```

2. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f auto-instrumentation/otelcol-cr.yaml
   ```

3. Install the application to be instrumented, like Keycloak
   ```terminal
   kubectl apply -f auto-instrumentation/keycloak.yaml
   kubectl wait --for=condition=Available deployments/keycloak
   ```

4. Play with the application, so that it generates telemetry
   ```terminal
   kubectl port-forward svc/keycloak 8080
   ```

5. Open the Grafana instance, go to Explore, and select the appropriate datasource, such as "Tempo".
   ```terminal
   kubectl port-forward -n lgtm svc/lgtm 3000
   ```

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Operator v0.125.0
- OpenTelemetry Collector v0.125.0
- Keycloak 26.2
