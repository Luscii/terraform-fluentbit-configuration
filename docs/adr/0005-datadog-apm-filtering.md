# Datadog APM Trace Log Filtering

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

Applications instrumented with Datadog APM (Application Performance Monitoring) emit trace logs containing correlation IDs and span information. These logs need to be:

1. Identified and filtered from regular application logs
2. Parsed correctly for timestamp extraction
3. Sent to Datadog for trace-log correlation
4. Distinguished from regular application logs

The module needs a dedicated parser/filter configuration for Datadog APM logs while allowing the same application to also emit regular logs through other technologies (e.g., PHP, .NET).

## Decision Drivers

* Datadog APM instrumentation adds trace logs to application output
* Trace logs have specific format: contains "Luscii APM" identifier
* Need to correlate traces with logs in Datadog
* Should only forward logs that contain APM information
* Must extract timestamp from datetime field
* Should work alongside other technology configurations
* Should follow parser-filter architecture (ADR-0002)

## Considered Options

* Filter APM logs in existing technology parsers (e.g., PHP)
* **Dedicated "datadog" technology with APM-specific filtering** (chosen)
* Post-processing filter after all parsing

## Decision Outcome

**Chosen option:** "Dedicated datadog technology", because it provides clean separation between application logs and APM trace logs, allows applications to use both, and makes the filtering logic explicit and testable.

### Implementation

**Parser (1 total):**

1. **datadog_json** - Parse Datadog APM JSON logs
   - Format: json
   - Time key: datetime
   - Time format: %Y-%m-%dT%H:%M:%S%z (ISO 8601)
   - Use case: Datadog APM instrumented applications

**Filters (2 total):**

1. **grep** - Include only APM trace logs
   - Regex: "log Luscii APM"
   - Purpose: Filter out non-APM logs, keep only trace logs

2. **modify** - Add metadata
   - Adds: log_source = "datadog"
   - Purpose: Identify Datadog APM logs in Datadog

### Usage Pattern

Applications can specify both their primary technology AND datadog:

```hcl
log_sources = [
  {
    name      = "php"
    container = "app"
  },
  {
    name      = "datadog"
    container = "app"
  }
]
```

This results in:
- Regular PHP logs parsed by PHP parsers → all logs sent
- Same logs also parsed by datadog parser → only APM traces sent

### Consequences

**Positive:**

* Clean separation of APM trace logs from application logs
* Easy to identify which logs contain APM correlation data
* Works alongside any other technology (PHP, .NET, Nginx)
* Simple grep filter ensures only APM logs are processed
* No impact on applications without APM instrumentation
* Clear metadata for Datadog log source identification

**Negative:**

* Applications using APM need to specify technology twice
* Same log stream is parsed twice (once for app logs, once for APM)
* Could result in duplicate log processing (mitigated by grep filter)
* "Luscii APM" string is hardcoded in filter

**Neutral:**

* Requires applications to emit "Luscii APM" in trace logs
* Datadog parser only processes logs that pass grep filter
* No custom parsers typically needed for Datadog APM

### Confirmation

Success will be confirmed when:
* datadog-config.tftest.hcl passes all tests
* Only logs containing "Luscii APM" are captured
* Timestamp extracted correctly from datetime field
* log_source metadata appears correctly
* Integration with terraform-aws-ecs-fargate-datadog-container-definitions works
* APM traces correlate with logs in Datadog UI

## Implementation Plan

### Agent Tasks

**1. scenario-shaper** - Create scenario:
- File: `docs/features/datadog-logging.feature`
- Scenarios:
  - Parse Datadog APM JSON logs
  - Filter for "Luscii APM" identifier
  - Exclude non-APM logs
  - Add log_source metadata
  - Multi-technology setup (PHP + Datadog)
  - Verify timestamp extraction

**2. terraform-tester** - Create tests:
- File: `tests/datadog-config.tftest.hcl`
- Tests:
  - Validate datadog_json parser structure
  - Validate grep filter with "Luscii APM" regex
  - Validate modify filter adds log_source
  - Validate parsers_map contains "datadog"
  - Validate filters_map contains "datadog"
  - Test multi-technology configuration
  - Validate time format
  - Integration test

**3. terraform-module-specialist** - Already implemented ✅
- datadog-config.tf is complete
- No code changes needed

**4. documentation-specialist** - Update docs:
- Add Datadog APM section to README.md
- Explain APM trace log filtering
- Document multi-technology usage pattern
- Provide APM instrumentation example
- Explain "Luscii APM" identifier requirement

**5. examples-specialist** - Add examples:
- Add Datadog example to examples/complete/main.tf
- Show multi-technology setup (PHP + Datadog)
- Demonstrate APM trace log filtering
- Show expected log format

## More Information

**Current Implementation:**
- File: datadog-config.tf ✅ (implemented)
- Tests: ❌ Missing tests/datadog-config.tftest.hcl
- Scenarios: ❌ Missing docs/features/datadog-logging.feature
- Examples: ❌ Missing Datadog example in examples/

**Related:**
- ADR-0002 - Parser-Filter Architecture
- datadog-config.tf implementation
- Datadog APM documentation: https://docs.datadoghq.com/tracing/

**APM Log Example:**

```json
{
  "datetime": "2026-01-22T10:30:45+0000",
  "message": "Luscii APM trace started",
  "level": "INFO",
  "dd.trace_id": "1234567890",
  "dd.span_id": "9876543210",
  "service": "api",
  "env": "production"
}
```

**Application Setup:**

Applications need to:
1. Enable Datadog APM instrumentation
2. Configure logs to include "Luscii APM" identifier in trace logs
3. Emit JSON-formatted logs with "datetime" field
4. Specify both application technology AND "datadog" in log_sources

**Why "Luscii APM" identifier?**
- Distinguishes APM trace logs from regular logs
- Prevents all application logs from being processed twice
- Provides clear filter criteria
- Can be configured in APM instrumentation
