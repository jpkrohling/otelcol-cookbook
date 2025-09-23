# 🍜 Recipe: OTTL Example 01 - Basic Transformations

This recipe demonstrates basic usage of the OpenTelemetry Transformation Language (OTTL) with the transform processor. It shows two common transformation patterns:
1. **Normalizing HTTP methods**: Converting HTTP method values to uppercase for consistency
2. **Removing sensitive data**: Deleting password attributes from logs for security

## 🎯 What You'll Learn

- How to use OTTL's `set()` function to modify attribute values
- How to use OTTL's `ToUpperCase()` converter function
- How to use OTTL's `delete_key()` function to remove sensitive attributes
- How to work with different OTTL contexts (span and log)

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- The `trace.json` and `logs.json` files from this directory
- `curl` or any tool capable of sending HTTP requests

## 🥣 Preparation

1. Start the OpenTelemetry Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config ottl/example-01/otelcol.yaml
   ```

2. In another terminal, send the trace data with lowercase HTTP method:
   ```terminal
   curl -X POST http://localhost:4318/v1/traces \
     -H "Content-Type: application/json" \
     -d @ottl/example-01/trace.json
   ```

3. Send the log data containing a password attribute:
   ```terminal
   curl -X POST http://localhost:4318/v1/logs \
     -H "Content-Type: application/json" \
     -d @ottl/example-01/logs.json
   ```

## 🔍 What to Observe

### For Traces
The collector will output the transformed span where:
- The `http.method` attribute value "get" is transformed to "GET"
- Original: `"http.method": "get"`
- After OTTL: `"http.method": "GET"`

### For Logs
The collector will output the transformed log where:
- The `password` attribute is completely removed from the log attributes
- Original attributes include: `user.id`, `password`, `session.id`, `auth.method`, `timestamp`
- After OTTL: The `password` attribute is deleted, only safe attributes remain

## 📖 Understanding the OTTL Statements

### Statement 1: Uppercase HTTP Method
```yaml
set(span.attributes["http.method"], ToUpperCase(span.attributes["http.method"]))
```
- **Context**: `span` - operates on trace spans
- **Function**: `set()` - an editor function that modifies data
- **Converter**: `ToUpperCase()` - converts string to uppercase
- **Purpose**: Ensures consistent HTTP method formatting

### Statement 2: Delete Password Attribute
```yaml
delete_key(log.attributes, "password")
```
- **Context**: `log` - operates on log records
- **Function**: `delete_key()` - an editor function that removes a map key
- **Purpose**: Removes sensitive data before export

## 🎓 Key Concepts

1. **OTTL Contexts**: Different telemetry signals (traces, logs, metrics) have different contexts with specific available paths
2. **Editor Functions**: Functions that transform data (lowercase names like `set`, `delete_key`)
3. **Converter Functions**: Functions that return values (uppercase names like `ToUpperCase`, `Concat`)
4. **Security Best Practice**: Always remove or redact sensitive data like passwords, tokens, and PII

## 🚀 Next Steps

Try modifying the OTTL statements to:
- Add a condition using `where`: `set(...) where span.attributes["http.method"] != nil`
- Use other converter functions: `ToLowerCase()`, `Concat()`, `Split()`
- Transform other attributes or add new ones
- Explore pattern matching with `IsMatch()` and `replace_pattern()`

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.120.0+
- OTTL syntax compatible with collector versions supporting transform processor

## 📚 Learn More

See the [OTTL Complete Guide](../OTTL-Complete-Guide.md) for comprehensive documentation on:
- All available functions and converters
- Advanced transformation patterns
- Performance optimization tips
- Security and privacy considerations