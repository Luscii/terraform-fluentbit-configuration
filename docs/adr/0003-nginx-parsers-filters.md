# Nginx JSON Access Log Parser and Error Log Support

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

The module needs to support Nginx containers running in ECS Fargate. Nginx produces two types of logs:

1. **Access logs** - HTTP request logs in JSON format (custom log_format configured in nginx.conf)
2. **Error logs** - Nginx error messages in standard Nginx error format

These logs need appropriate parsers to extract structured data and filters to enrich the logs for Datadog ingestion.

## Decision Drivers

* Nginx is widely used as reverse proxy/ingress in ECS Fargate
* Access logs are pre-configured in JSON format for easy parsing
* Error logs use standard Nginx format with specific regex pattern
* Need to distinguish between access and error logs
* Need to enrich logs with source metadata
* Should follow the parser-filter architecture pattern (ADR-0002)

## Considered Options

* Single parser for all Nginx logs
* **Three parsers: nginx_json, nginx_access (regex), nginx_error (regex)** (chosen)
* Separate technology names for access vs error logs

## Decision Outcome

**Chosen option:** "Three parsers with single nginx technology", because Nginx can output logs in different formats and we need to handle both JSON-formatted access logs and traditional regex-based access/error logs, all under one technology identifier.

### Implementation

**Parsers:**

1. **nginx_json** - Primary parser for JSON-formatted access logs
   - Format: json
   - Time key: time_local
   - Time format: %d/%b/%Y:%H:%M:%S %z
   - Use case: Nginx configured with custom JSON log_format

2. **nginx_access** - Fallback parser for standard access log format
   - Format: regex
   - Regex: Combined log format with optional referer/user-agent
   - Time format: %d/%b/%Y:%H:%M:%S %z
   - Use case: Default Nginx access log format

3. **nginx_error** - Parser for Nginx error logs
   - Format: regex
   - Regex: Nginx error format (time, level, pid, tid, message)
   - Time format: %Y/%m/%d %H:%M:%S
   - Use case: Nginx error.log output

**Filters:**

1. **modify** - Add metadata
   - Adds: log_source = "nginx"
   - Purpose: Identify Nginx logs in Datadog

### Consequences

**Positive:**

* Handles both JSON and traditional log formats
* Supports access and error logs
* Clear parser names indicate purpose
* Consistent with parser-filter architecture
* Easy to understand which parser handles what

**Negative:**

* Multiple parsers for one technology (could be confusing)
* Fluent Bit will try all parsers until one succeeds (performance consideration)
* Need to ensure nginx.conf uses JSON format for optimal parsing

**Neutral:**

* All three parsers grouped under "nginx" technology
* Container-specific filtering works uniformly

### Confirmation

Success will be confirmed when:
* nginx-config.tftest.hcl passes all tests (10+ assertions)
* JSON access logs parse correctly
* Standard access logs parse correctly
* Error logs parse correctly
* log_source metadata appears in Datadog
* Integration with terraform-aws-ecs-fargate-datadog-container-definitions works

## Implementation Plan

### Agent Tasks

**1. scenario-shaper** - Create scenario:
- File: `docs/features/nginx-logging.feature`
- Scenarios:
  - JSON access log parsing
  - Standard access log parsing (regex)
  - Error log parsing
  - Container-specific routing
  - Log metadata enrichment

**2. terraform-tester** - Create tests:
- File: `tests/nginx-config.tftest.hcl`
- Tests:
  - Validate 3 parsers exist
  - Validate nginx_json parser structure
  - Validate nginx_access regex parser
  - Validate nginx_error regex parser
  - Validate modify filter
  - Validate parsers_map contains "nginx"
  - Validate filters_map contains "nginx"
  - Validate time format configurations
  - Validate filter field structure
  - Integration test with complete configuration

**3. terraform-module-specialist** - Already implemented ✅
- nginx-config.tf is complete
- No code changes needed

**4. documentation-specialist** - Update docs:
- Add Nginx section to README.md
- Document parser selection logic
- Provide nginx.conf example for JSON logging
- Explain when each parser is used

**5. examples-specialist** - Add examples:
- Add nginx example to examples/complete/main.tf
- Show JSON access log configuration
- Show error log handling
- Demonstrate container-specific routing

## More Information

**Current Implementation:**
- File: nginx-config.tf ✅ (implemented)
- Tests: ❌ Missing tests/nginx-config.tftest.hcl
- Scenarios: ❌ Missing docs/features/nginx-logging.feature
- Examples: ❌ Missing nginx example in examples/

**Related:**
- ADR-0002 - Parser-Filter Architecture
- nginx-config.tf implementation
- Integration with ECS Fargate container definitions

**Nginx Log Format Examples:**

JSON access log format (nginx.conf):
```nginx
log_format json_combined escape=json
  '{'
    '"time_local":"$time_local",'
    '"remote_addr":"$remote_addr",'
    '"request_method":"$request_method",'
    '"request_uri":"$request_uri",'
    '"status":$status,'
    '"body_bytes_sent":$body_bytes_sent,'
    '"http_referer":"$http_referer",'
    '"http_user_agent":"$http_user_agent"'
  '}';

access_log /var/log/nginx/access.log json_combined;
```

Standard access log:
```
192.168.1.1 - - [22/Jan/2026:10:30:45 +0000] "GET /api/health HTTP/1.1" 200 15 "-" "ELB-HealthChecker/2.0"
```

Error log:
```
2026/01/22 10:30:45 [error] 123#456: *789 connect() failed (111: Connection refused)
```
