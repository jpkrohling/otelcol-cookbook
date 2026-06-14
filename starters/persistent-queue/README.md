# 🍜 Recipe: Persistent Sending Queue

The Collector's sending queue lives in memory by default, so anything still queued is lost if the process restarts during a backend outage. This recipe backs the queue with the `file_storage` extension so buffered telemetry is written to disk — it survives both a long outage and a Collector restart, and drains to the backend once it comes back.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | filestorage, otlpexporter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- A downstream OTLP endpoint (another collector or backend) at `backend:4317` — or edit the `endpoint` to match yours
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration, **with the backend still down**:
   ```terminal
   otelcol-contrib --config starters/persistent-queue/otelcol.yaml
   ```

2. Send some traces:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 50
   ```
   The collector accepts them and returns success to the client immediately. Because the
   backend is unreachable, it logs `Exporting failed. Will retry...` and buffers the
   batches to disk under `/var/lib/otelcol/storage` (one bbolt file, `exporter_otlp__traces`).

3. Restart the collector (`Ctrl-C`, then start it again). On startup it logs
   `Loaded queue metadata` with a non-zero `itemsSize` — the queued batches were read back
   from disk, where an in-memory queue would have lost them.

4. Bring the backend up. The collector drains the disk-backed queue and the traces arrive at
   the backend; delivery is paced by the exponential retry backoff, so allow a minute or two.

## 🎯 Key details

- `extensions.file_storage` must be listed under `service.extensions` to load; it writes one
  bbolt file per consumer into `directory`. `create_directory: true` creates that directory on
  startup instead of failing when it is missing.
- `exporters.otlp_grpc.sending_queue.storage: file_storage` is the switch that makes the queue
  persistent. Without it the queue is in-memory and a restart discards whatever it held.
- `retry_on_failure.max_elapsed_time: 0` retries forever, so a long outage never drops data.
  The default (`5m`) would drop batches once the budget is exhausted.
- Alternatives for the same goal: drop `storage` to keep the queue in memory (faster, but no
  restart durability — see [`blocking-exporter`](../blocking-exporter/) for the opposite,
  no-buffer choice), or place a broker between tiers and let it be the durable buffer
  (see [`mains/kafka-on-kubernetes`](../../mains/kafka-on-kubernetes/)).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
