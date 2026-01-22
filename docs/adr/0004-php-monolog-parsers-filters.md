# PHP Monolog JSON Parser with Multiple Datetime Formats

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

PHP applications using the Monolog logging library generate JSON-formatted logs, but the datetime field can appear in multiple ISO 8601 variants depending on Monolog configuration:

1. With timezone colon: `2026-01-15T08:59:58+00:00`
2. Without timezone colon: `2026-01-15T08:59:58+0000`
3. UTC with Z indicator: `2026-01-15T08:59:58Z`
4. With microseconds: `2026-01-15T08:59:58.123456+00:00`

Additionally, PHP error logs (not from Monolog) use a different format and need separate parsing. We need a solution that handles all these variations reliably.

## Decision Drivers

* Monolog datetime format varies based on PHP version and Monolog configuration
* Cannot predict which format a specific application will use
* Need to parse all variants correctly to extract timestamps
* Must handle both structured logs (Monolog JSON) and unstructured logs (PHP errors)
* Should filter out noise (deprecated warnings, access logs mixed in stderr)
* Must enrich logs with source metadata
* Should follow parser-filter architecture (ADR-0002)

## Considered Options

* Single parser with flexible datetime pattern
* **Multiple parsers, one for each datetime variant** (chosen)
* Parser with datetime normalization filter
* Require applications to standardize datetime format

## Decision Outcome

**Chosen option:** "Multiple parsers, one for each datetime variant", because Fluent Bit's parser filter tries parsers sequentially until one succeeds, allowing us to support all datetime variants without forcing application changes.

### Implementation

**Parsers (5 total):**

1. **php_monolog_json_tz_colon** - ISO 8601 with colon in timezone
   - Format: json
   - Time format: %Y-%m-%dT%H:%M:%S%:z
   - Example: 2026-01-15T08:59:58+00:00

2. **php_monolog_json_tz** - ISO 8601 without colon in timezone
   - Format: json
   - Time format: %Y-%m-%dT%H:%M:%S%z
   - Example: 2026-01-15T08:59:58+0000

3. **php_monolog_json_utc** - ISO 8601 with Z indicator
   - Format: json
   - Time format: %Y-%m-%dT%H:%M:%SZ
   - Example: 2026-01-15T08:59:58Z

4. **php_monolog_json_micro** - ISO 8601 with microseconds
   - Format: json
   - Time format: %Y-%m-%dT%H:%M:%S.%L%:z
   - Example: 2026-01-15T08:59:58.123456+00:00

5. **php_error** - Standard PHP error log format
   - Format: regex
   - Regex: `^\[(?<time>[^\]]*)\] (?<level>\w+): (?<message>.*)$`
   - Example: [22-Jan-2026 08:59:58 UTC] ERROR: Connection failed

**Filters (11 total):**

Grep filters (10) for noise reduction:
1. Exclude access log format lines (IP - timestamp "METHOD /index.php" status)
2. Exclude unstructured "PHP Deprecated:" messages
3. Exclude structured msg="PHP Deprecated:" messages
4. Exclude unstructured "PHP Warning:" messages
5. Exclude structured msg="PHP Warning:" messages
6. Exclude unstructured "PHP Notice:" messages
7. Exclude structured msg="PHP Notice:" messages
8. Exclude Composer warnings
9. Exclude Symfony deprecation warnings
10. Exclude generic debug noise patterns

Modify filter (1) for enrichment:
11. Add log_source = "php"

### Consequences

**Positive:**

* Handles all Monolog datetime format variants automatically
* No application code changes required
* Supports both structured (JSON) and unstructured (error) logs
* Extensive noise filtering reduces log volume and cost
* Clear parser names indicate which format they handle
* Easy to add new parsers if new formats emerge

**Negative:**

* Multiple parsers means Fluent Bit tries each until success (slight performance overhead)
* 10 grep filters may seem excessive (but each serves specific purpose)
* Need to maintain filter patterns as PHP/Monolog evolve
* Could miss legitimate logs if filter patterns are too aggressive

**Neutral:**

* All parsers attempt to parse the same "log" field
* Parser order doesn't matter (Fluent Bit tries all)
* Filters are applied after parsing succeeds

### Confirmation

Success confirmed by:
* ✅ php-config.tftest.hcl passes (29 tests, all passing)
* ✅ All 5 parsers validated
* ✅ All 11 filters validated
* ✅ Integration tests pass
* ✅ Used in production Luscii applications

## Implementation Plan

### Agent Tasks

**1. scenario-shaper** - Create scenario:
- File: `docs/features/php-logging.feature`
- Scenarios:
  - Parse Monolog JSON with timezone colon
  - Parse Monolog JSON with timezone no colon
  - Parse Monolog JSON with UTC Z
  - Parse Monolog JSON with microseconds
  - Parse PHP error log format
  - Filter out deprecated warnings
  - Filter out access logs in stderr
  - Add log_source metadata
  - Container-specific routing

**2. terraform-tester** - Already implemented ✅
- tests/php-config.tftest.hcl exists (29 tests passing)

**3. terraform-module-specialist** - Already implemented ✅
- php-config.tf complete and tested

**4. documentation-specialist** - Update docs:
- Add PHP section to README.md
- Document which Monolog datetime formats are supported
- Explain the noise filtering strategy
- Provide Monolog configuration example
- Document when to use custom filters

**5. examples-specialist** - Add examples:
- Add PHP example to examples/complete/main.tf
- Show Monolog JSON configuration
- Demonstrate custom filter addition
- Show multi-container PHP setup

## More Information

**Current Implementation:**
- File: php-config.tf ✅ (implemented)
- Tests: ✅ tests/php-config.tftest.hcl (29 passing tests)
- Scenarios: ❌ Missing docs/features/php-logging.feature
- Examples: ❌ Missing PHP example in examples/

**Related:**
- ADR-0002 - Parser-Filter Architecture
- php-config.tf implementation
- tests/php-config.tftest.hcl

**Monolog Configuration Example:**

```php
<?php
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Formatter\JsonFormatter;

$log = new Logger('app');
$handler = new StreamHandler('php://stdout', Logger::DEBUG);
$handler->setFormatter(new JsonFormatter());
$log->pushHandler($handler);

// Results in logs like:
// {"message":"User logged in","level":"INFO","datetime":"2026-01-22T10:30:45+00:00"}
```

**Test Results:**
```
Success! 29 passed, 0 failed.
- 5 parser structure tests
- 11 filter tests (10 grep + 1 modify)
- 13 integration and edge case tests
```

**Known Limitations:**
- Does not support Monolog's Fluentd formatter (different structure)
- Custom Monolog formatters may require custom parser definitions
- Noise filters may need tuning per application
