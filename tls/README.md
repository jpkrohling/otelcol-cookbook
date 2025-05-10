# 🍜 Recipe: TLS

This recipe shows how to configure TLS encryption for the OpenTelemetry Collector's OTLP receiver. By default, the OTLP receiver accepts unencrypted connections, which might not be suitable for production environments. This recipe demonstrates how to generate TLS certificates and configure the Collector to use them for secure communication.

We have the following endpoints available:

* `localhost:4318`, as an insecure endpoint, receiving telemetry and sending to a secure endpoint
* `localhost:5318`, as a secure endpoint, sending the telemetry to the telemetry backend on `localhost:6318`

We'll send telemetry to both the local insecure endpoint (`4318`) and secure (`5318`), so that we have examples of client and server configuration.

## 🧄 Ingredients

- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol.yaml` file from this directory
- The `cert-csr.json` and `ca-csr.json` from this directory. Optional if you have your own TLS certs already.
- `cfssl`, or any other tool that is able to generate TLS certificates. Optional if you have your own TLS certs already.

## 🥣 Preparation

1. Start a LGTM container exposing the OTLP HTTP port to `6318`, to receive the telemetry from our Collectors
   ```terminal
   docker run --name lgtm -p 3000:3000 -p 6318:4318 --rm -d grafana/otel-lgtm
   ```

1. Generate the TLS certificate files. In our example, we are using [`cfssl`](https://github.com/cloudflare/cfssl)
   ```terminal
   cfssl genkey -initca ca-csr.json | cfssljson -bare ca
   cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
   cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
   ```

2. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

3. Send some telemetry to your insecure endpoint
   ```terminal
   telemetrygen traces --otlp-attributes='recipe="tls"' --otlp-attributes='variant="insecure"' --otlp-http --otlp-endpoint localhost:4318 --otlp-insecure
   ```

4. Send some telemetry to your secure endpoint
   ```terminal
   telemetrygen traces --otlp-attributes='recipe="tls"' --otlp-attributes='variant="secure"' --otlp-http --otlp-endpoint localhost:5318 --ca-cert ca.pem
   ```

5. Open `localhost:3000` and explore the available traces, which should include traces from our application's telemetry (`lets-go`, from `telemetrygen`) and the internal Collector traces (HTTP and gRPC).

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.123.0
- `telemetrygen` v0.123.0
