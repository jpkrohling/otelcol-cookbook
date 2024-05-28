# Simple recipes

This is a collection of simple recipes, showing individual features.

## Simplest

This is the simplest configuration possible for traces, metrics, and logs. You can use it to test telemetry being created by your application, likely using the OpenTelemetry API and SDK.

You can test the `simplest.yaml` recipe with the `telemetrygen`:

```commandline
telemetrygen traces --traces 1000 --otlp-insecure 
```

And the following should be seen in the Collector console:

```
2023-11-02T10:31:48.664-0300    info    TracesExporter  {"kind": "exporter", "data_type": "traces", "name": "debug", "resource spans": 1, "spans": 512}
2023-11-02T10:31:48.670-0300    info    TracesExporter  {"kind": "exporter", "data_type": "traces", "name": "debug", "resource spans": 1, "spans": 512}
```

## Include

This shows how to split the Collector configuration in multiple files. Things to note:
- `include.yaml` file has a reference to `include-debug-exporter.yaml`, which resides on the same directory
- however, the path to `include-debug-exporter.yaml` is relative to working directory that started the command. Try running this example from both the root of this repository and from _this_ repository to see the difference.

You can test this configuration in the exact same way as the [Simplest](#simplest) recipe.

## Blocking

This shows how to disable the default asynchronous behavior of the Collector. We are disabling the sending queue, meaning that the Collector will block until the data is sent to the configured exporters. The retry mechanism is still enabled, so if the exporter fails to send the data, the Collector will retry until it succeeds, or until the timeout is reached.

## Resilient log pipeline

This example shows how to configure a log pipeline that will use a WAL to buffer the telemetry data before sending it out to an external OTLP endpoint. Should this external OTLP endpoint go offline for a reason, data will still be retried once it comes back.

To test this, we'll our resilient Collectors with the `resilient-log-pipeline.yaml` configuration. You can start a second Collector locally similar to the `simplest.yaml` with a few changes, so that ports won't clash.

```commandline
mkdir /tmp/otc
otelcol-contrib --config recipes/simple/resilient-log-pipeline.yaml
```

We now send some telemetry data to our Collector, to make sure everything works as expected: