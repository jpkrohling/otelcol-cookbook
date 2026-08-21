# 🍜 Recipe: Redact PII in Log Bodies

Applications often log sensitive data inside the free-text message itself — an email address, a card number — where it can't be masked by clearing a single attribute. This recipe uses the `transform` processor's `replace_pattern` to find and rewrite those patterns directly in the log body.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | transformprocessor (OTTL `replace_pattern`) |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/redact-log-body/otelcol.yaml
   ```

2. Send a log whose body contains PII:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 \
     --body "user jdoe@example.com paid order 12 with card 4111 1111 1111 1111"
   ```

3. Watch the collector output. The body is rewritten in place, while non-matching text (the order
   number `12`) is untouched:
   ```
   Body: Str(user <redacted-email> paid order 12 with card <redacted-card>)
   ```

## 🎯 Key details

- `replace_pattern(log.body, "<regex>", "<replacement>")` rewrites every match in the string. The
  statements run in order, so the email is masked first, then the card number.
- The patterns use character classes (`[0-9]`, `[a-zA-Z0-9._%+-]`) rather than `\d`/`\.` shorthand
  to avoid a second layer of backslash escaping inside the OTTL string literal. OTTL uses Go's RE2
  engine — no backreferences or lookarounds.
- `error_mode: ignore` keeps the pipeline running if a statement can't evaluate a particular record
  (e.g. a non-string body) instead of dropping it.
- This masks PII inside an unstructured message. To clear a whole **attribute** instead — on a span
  or log — set it to a constant; see [`redact-pii`](../redact-pii/). For richer rules (hashing,
  allow/block lists, built-in sanitizers) the dedicated `redaction` processor is the heavier option.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
