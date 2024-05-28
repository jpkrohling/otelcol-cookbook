# 🍜 Recipe: Kafka on Kubernetes

This recipe uses a Kafka cluster between two layers of Collectors, showing how to scale a collection pipeline that is able to absorb spikes in traffic without putting extra pressure on the backend. The idea is that the first layer might scale according to the demand, sending data to Kafka, which is consumed by a static set of Collectors. This architecture is suitable for scaling Collectors when the backend can eventually catch-up with the traffic, as is usually the case with sudden spikes.

Note that we've used the `transform` processor to add the current timestamp to all spans at both layers (`published_at` and `consumed_at`), so that we know when we sent something to the queue, and when we've consumed it from the queue.

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../README.md) for instructions
- A Kafka Cluster and one topic for each telemetry data type (metric, logs, traces)
- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol-cr.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Install [Strimzi](https://strimzi.io), a Kubernetes Operator for Kafka
    ```terminal
    kubectl create ns kafka
    kubens kafka

    kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka'
    kubectl wait --for=condition=Available deployments/strimzi-cluster-operator --timeout=300s
    ```

2. Install the Kafka cluster and topics for our recipe
    ```terminal
    kubectl apply -f kafka-for-otelcol.yaml
    kubectl wait kafka/kafka-for-otelcol --for=condition=Ready --timeout=300s
    ```

3. Create and switch to a namespace for our recipe
    ```terminal
    kubectl create ns kafka-on-kubernetes
    kubens kafka-on-kubernetes
    ```

4. Create a secret with the credentials: 
   ```terminal
    kubectl create secret generic grafana-cloud-credentials --from-literal=GRAFANA_CLOUD_USER="$GRAFANA_CLOUD_USER" --from-literal=GRAFANA_CLOUD_TOKEN="$GRAFANA_CLOUD_TOKEN"
   ```

5. Create the OTel Collector custom resources that publishes to and consumes from the Kafka topic
    ```terminal
    kubectl apply -f otelcol-pub.yaml
    kubectl apply -f otelcol-sub.yaml
    kubectl wait --for=condition=Available deployments/otelcol-pub-collector
    kubectl wait --for=condition=Available deployments/otelcol-sub-collector
    ```

6. Open a port-forward to the Collector that is publishing to Kafka: 
   ```terminal
   kubectl port-forward svc/otelcol-pub-collector 4317
   ```

7. Send some telemetry to your Collector
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="kafka-on-kubernetes"'
   ```

8. Open your Grafana instance, go to Explore, and select the appropriate datasource, such as "...-traces". If used the command above, click "Search" and you should see two traces listed, each with two spans.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- Strimzi v0.41.0
- OpenTelemetry Operator v0.100.1
- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
