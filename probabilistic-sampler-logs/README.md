# 🍜 Recipe: Probabilistic sampler with logs

This recipe shows how to apply the probabilistic sampler with logs. Typically, this sampler would be applied to traces, so that a consistent decision is applied to all spans in a trace. For logs, this is a bit more nuanced: if we have a traceID in our logs, we can use that to ensure we get all logs for a given trace. This means that the message is static, and one attribute is transaction-related. When traceID is missing, we need a similar attribute that changes on a per-transaction basis. This way, we still get ~all messages, just for different transactions.

Logs aren't only for applications though: it's common to use OTel Collector to collect regular logs from a system. Ideally, we'd store all such logs and find different ways to filter them out. When setting up a new telemetry pipeline, it might be worth to randomly discard items. In that case, we can hash the body of the log record using the "FNV" function from OTTL, store the results in a record attribute, and then use that as the source of randomness to the probabilistic sampling rocessor.

## 🧄 Ingredients

- The `otelcol.yaml` file from this directory

## 🥣 Preparation

1. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

2. Verify how many log records were accepted and refused by the sampler by checking the metrics on http://localhost:8888/metrics :
   ```terminal
   otelcol_processor_probabilistic_sampler_count_logs_sampled{policy="body.hash",sampled="false",service_instance_id="01a0ae86-81fc-489b-bc52-3c348f6cd24b",service_name="otelcol-contrib",service_version="0.113.0"} 11038
   otelcol_processor_probabilistic_sampler_count_logs_sampled{policy="body.hash",sampled="true",service_instance_id="01a0ae86-81fc-489b-bc52-3c348f6cd24b",service_name="otelcol-contrib",service_version="0.113.0"} 1247
   ```

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.113.0
