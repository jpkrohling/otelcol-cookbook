# Tail-sampling recipes

This is a collection of recipes featuring the tail-sampling processor.

## Always on

This is there just to test whether we have everything wired up correctly. This will effectively sample everything, which is pretty much the same behavior as without the tail-sampling processor.

You can test the `always-on.yaml` recipe with the `telemetrygen`:

```commandline
telemetrygen traces --traces 1_000 --otlp-insecure 
```

There should be a few lines like the one below in the Collector logs:

```
2023-11-02T12:39:08.227-0300    info    TracesExporter  {"kind": "exporter", "data_type": "traces", "name": "debug", "resource spans": 1, "spans": 2}
```

What's interesting here is that we can check the metrics that are emitted by the tail-sampling processor. In your browser, go to `http://localhost:8888/metrics` and look at the metrics starting with `otelcol_processor_tail_sampling_`, like:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="always-on",sampled="true",service_instance_id="e86a802a-826c-4b16-96ee-1688fa74ed1d",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="e86a802a-826c-4b16-96ee-1688fa74ed1d",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="e86a802a-826c-4b16-96ee-1688fa74ed1d",service_name="otelcol-contrib",service_version="0.88.0"} 1000
```

Given that the decision time is 1s for this processor, you might not see the metrics if you are too quick. Try increasing the decision wait to see the effect on the metrics.

## Probabilistic

When using this policy along, it's likely better to use the probabilistic sampling processor instead, but this is useful when combined with other policies. The `probabilistic` example shows how to use this policy individually.

Test the `probabilistic.yaml` recipe like the [Always on](#always-on) recipe and see how the metrics differ. Note that this is _probabilistic_, meaning that there's a 10% _chance_ that a trace will be sampled. This is different than saying that 10% of the traces WILL be sampled.

Here are some metrics from one specific execution showing that we got 9.3% of the traces sampled:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="false",service_instance_id="291ccd98-8745-4246-b7ff-46ffe1f4c6b4",service_name="otelcol-contrib",service_version="0.88.0"} 907
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="true",service_instance_id="291ccd98-8745-4246-b7ff-46ffe1f4c6b4",service_name="otelcol-contrib",service_version="0.88.0"} 93
```

## Spans with specific attribute values

The `vip` recipe shows how to make a decision based on traces containing a span with specific attribute values. In this case, we are looking for traces containing spans with the `vip` attribute set to `true`. Traces that do not contain such spans will be NOT be sampled.

Start the collector with the `vip.yaml` recipe and run the `telemetrygen` test:

```commandline
telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='vip="true"'
```

Here's what we should see in our metrics. Note the absence of the `sampled=false` time series:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="vip",sampled="true",service_instance_id="dac1e38c-ea76-4abb-966a-e643d2dc5f3a",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="dac1e38c-ea76-4abb-966a-e643d2dc5f3a",service_name="otelcol-contrib",service_version="0.88.0"} 1000
```

Running `telemetrygen` again but setting the flag to true causes the new time series to appear, denoting that all new traces were NOT samples:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="vip",sampled="false",service_instance_id="dac1e38c-ea76-4abb-966a-e643d2dc5f3a",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="dac1e38c-ea76-4abb-966a-e643d2dc5f3a",service_name="otelcol-contrib",service_version="0.88.0"} 2000
```

## Invert match

Some policies, like the `string_attribute`, have the ability to invert the decision when a match happens. The `not-vip.yaml` recipe shows that: it's the opposite of the [Spans with specific attribute values](#spans-with-specific-attribute-values) recipe. In this case, we are matching traces that do NOT contain spans with the `vip` attribute set to `true`.

Run the same tests from the [Spans with specific attribute values](#spans-with-specific-attribute-values) recipe, but with the `not-vip.yaml` recipe. You should see the same metrics, but with the `sampled=true` and `sampled=false` time series inverted.

## Multiple policies

There are times we want to make a decision based on multiple conditions. The `multiple.yaml` recipe shows how to do that. In this case, we are sampling 100% of the traces containing spans with the `vip` attribute set to `true`, and 10% of the remaining traces.

Start the collector with the `multiple.yaml` recipe and run the first `telemetrygen` test:

```commandline
telemetrygen traces --traces 1_000 --otlp-insecure --otlp-attributes='vip="true"'
```

Here are the relevant metrics:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="false",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 924
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 76
otelcol_processor_tail_sampling_count_traces_sampled{policy="vip",sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1000
```

This tells us that we saw 1000 unique trace IDs, and we sampled 1000 of them. Even though the `only-10-percent` policy would have sampled 76 of the traces, we sampled 100% of the traces because of the `vip` policy.

Running another test, now with the `vip` attribute set to `false`, we see these metrics:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="false",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1821
otelcol_processor_tail_sampling_count_traces_sampled{policy="only-10-percent",sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 179
otelcol_processor_tail_sampling_count_traces_sampled{policy="vip",sampled="false",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_count_traces_sampled{policy="vip",sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1000
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="false",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 897
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 1103
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="b14ed6c2-c478-4bd6-8a56-bba2aaa962be",service_name="otelcol-contrib",service_version="0.88.0"} 2000
```

This tells us that we saw 2000 unique trace IDs, sampling 1103 of them. The `vip` policy resulted in 1000 traces being sampled, and 1000 traces not being sampled. The `only-10-percent` policy resulted in 179 traces being sampled in total, 103 of them being from this second test, which is roughly 10% of the new traces.

## "And" policy

Having multiple policies means that policies making a "Sample" decision might override a previous "NotSample" decision. The `and.yaml` recipe shows how to use the `and` policy to make sure that all policies must agree on a "Sample" decision for a trace to be sampled.

Wrapping the [Multiple policies](#multiple-policies) recipe with an `and` policy, we see different results when running the `telemetrygen` with the `vip` attribute set to `true`:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="",sampled="false",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 912
otelcol_processor_tail_sampling_count_traces_sampled{policy="",sampled="true",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 88
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="false",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 912
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 88
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 1000
```

Here, instead of getting 100% sampling for traces containing spans with the `vip` attribute set to `true`, we got 8.8% sampling, which is roughly 10%, as defined in the `probabilistic` sub-policy. Perhaps counter-intuitively, we get a 100% sampling rate for traces without spans containing the `vip` attribute set to `true`:

```
otelcol_processor_tail_sampling_count_traces_sampled{policy="",sampled="false",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 1912
otelcol_processor_tail_sampling_count_traces_sampled{policy="",sampled="true",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 88
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="false",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 1912
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 88
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="17e959f6-716a-4eeb-a4cb-5b17a8982fe1",service_name="otelcol-contrib",service_version="0.88.0"} 2000
```

## Multiple policies with "and"

A more complex scenario was requested some time ago, and consists of sampling only 2% of the successful requests to a specific endpoint, sampling 100% of everything else. This is a common case where services have a couple of busy endpoints, and we want to sample those, but not the rest of the traffic.