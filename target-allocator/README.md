# 🍜 Recipe: Target Allocator

Coming soon.

## 🧄 Ingredients

Coming soon.

## 🥣 Preparation

0. Install Prometheus CRDs for `PodMonitor` and `ServiceMonitor`
   ```terminal
   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
   ```

1. Create and switch to a namespace for our recipe
   ```terminal
    kubectl create ns target-allocator-recipe
    kubens target-allocator-recipe
   ```

2. Install the OTel Collector custom resource
   ```terminal
   kubectl apply -f target-allocator/role.yaml
   kubectl apply -f target-allocator/svc.yaml
   kubectl apply -f target-allocator/otelcol-cr.yaml
   ```

3. Create a sample application that exposes Prometheus metrics
   ```terminal
   kubectl apply -f target-allocator/workload.yaml
   ```

5. Install a custom service for our workload and service monitor, telling Target Allocator which pods have Prometheus targets
   ```terminal
   kubectl apply -f target-allocator/svc.yaml
   ```

9.  Open your Grafana instance, go to Explore, and select the metrics data source


## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
