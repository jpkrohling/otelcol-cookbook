# 🍜 Recipe: Kafka on Kubernetes

Put a Kafka topic between two layers of Collectors to absorb traffic spikes. A front
(*publisher*) layer can scale with demand and write to Kafka; a static *subscriber* layer drains
the topic at its own pace. This decouples ingestion from the backend, which is ideal when the
backend can catch up after a burst. Each layer stamps a timestamp (`published_at`, `consumed_at`)
so you can measure how long data sat in the queue.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | Kubernetes |
| **Key components** | kafkaexporter, kafkareceiver, transformprocessor |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- [Strimzi](https://strimzi.io) (Kafka Operator) and the `kafka-for-otelcol.yaml` cluster manifest
- The `otelcol-pub.yaml` and `otelcol-sub.yaml` from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Install Strimzi and wait for its operator:
   ```terminal
   kubectl create ns kafka
   kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
   kubectl -n kafka wait --for=condition=Available deployments/strimzi-cluster-operator --timeout=300s
   ```

2. Create the Kafka cluster and topics, then wait for it to be ready:
   ```terminal
   kubectl -n kafka apply -f kafka-for-otelcol.yaml
   kubectl -n kafka wait kafka/kafka-for-otelcol --for=condition=Ready --timeout=420s
   ```

3. Deploy the publisher and subscriber Collectors:
   ```terminal
   kubectl create ns kafka-on-kubernetes
   kubens kafka-on-kubernetes
   kubectl apply -f otelcol-pub.yaml
   kubectl apply -f otelcol-sub.yaml
   ```

4. Send traces to the publisher and watch the **subscriber's** `debug` output:
   ```terminal
   kubectl port-forward svc/otelcol-pub-collector 4317
   telemetrygen traces --traces 5 --otlp-insecure
   kubectl logs deploy/otelcol-sub-collector | grep -E 'published_at|consumed_at'
   ```
   Every span the subscriber prints carries both `published_at` (stamped before Kafka) and
   `consumed_at` (stamped after) — proof the trace made the full round-trip through the topic.

## 🎯 Key details

- The exporter writes to a single topic (`traces.topic: otlp-spans`); the receiver reads from a
  list (`traces.topics: [otlp-spans]`). These per-signal sections replaced the old top-level
  `topic` key — a top-level `topic` no longer validates.
- `initial_offset: earliest` keeps traces sent while the subscriber's consumer group is still
  joining Kafka. Without it, a new group can start after those records and skip the first test.
- `kafka-for-otelcol.yaml` uses a single-replica KRaft cluster (`KafkaNodePool` + `Kafka`, API
  version `kafka.strimzi.io/v1`) with replication factors of 1 — fine for a demo, not production.
- The two `transform` processors add `published_at` / `consumed_at` via `UnixMilli(Now())`; the
  gap between them is the in-queue latency.
- To also buffer metrics and logs, add their pipelines and point them at the `otlp-metrics` /
  `otlp-logs` topics this manifest already creates.

## 😋 Tested with

- Strimzi (latest), Kafka in KRaft mode
- OpenTelemetry Operator v0.156.0
- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
