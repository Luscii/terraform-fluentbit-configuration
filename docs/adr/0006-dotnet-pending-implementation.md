
# .NET Logging Support - Implemented

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team


## Context and Problem Statement

The module now provides full .NET logging support in `dotnet-config.tf`, with comprehensive parser and filter definitions, and complete test coverage. .NET applications can use various logging frameworks:

1. **Microsoft.Extensions.Logging** - Standard .NET Core logging
2. **Serilog** - Popular structured logging library
3. **NLog** - Flexible logging framework
4. **log4net** - Port of Java's log4j

We need to decide:
- Which .NET logging frameworks to support
- What log formats to expect (JSON, plain text, custom)
- What parser configurations are needed
- What filters are appropriate

## Decision Drivers

* No current Luscii applications using .NET on ECS Fargate
* Unclear which .NET logging framework would be used
* .NET logging can be highly customized
* Should follow parser-filter architecture (ADR-0002)
* Should wait for actual requirement before implementing

## Considered Options

* Implement generic .NET JSON parser immediately
* Implement Serilog-specific parser (most popular)
* **Wait for actual .NET application requirement** (proposed)
* Support all major .NET logging frameworks upfront


## Decision Outcome

**Chosen option:** "Implement .NET logging support based on real log samples and requirements". The module now includes:

1. Parsers for .NET text, JSON, and Serilog log formats
2. Filters for health check/static asset exclusion, profile image warnings, log level filtering, and log source enrichment
3. Container-specific match patterns for robust routing
4. Comprehensive tests in `tests/dotnet-config.tftest.hcl` covering all scenarios
5. Documentation and scenarios reflecting the actual implementation


### Current Implementation

The current implementation (see `dotnet-config.tf`):

- Defines three .NET parsers: `dotnet_text` (regex), `dotnet_json` (json), `dotnet_serilog` (json)
- Defines five .NET filters: two grep filters (health check/static asset exclusion, profile image warnings), one modify filter (log_source enrichment), and two loglevel filters (drop debug/trace, allow info/warn/error)
- Uses container-specific match patterns for robust routing
- All logic is fully tested in `tests/dotnet-config.tftest.hcl`


### Consequences

**Positive:**

* .NET logging support is now fully implemented and tested
* Parsers and filters are tailored to real .NET log formats (text, JSON, Serilog)
* Container-specific routing and enrichment is robust
* All scenarios are covered by tests and documentation
* Consistent with parser-filter architecture (ADR-0002)

**Negative:**

* Maintenance required if .NET log formats evolve
* Additional frameworks (e.g., NLog, log4net) may require future extension

**Neutral:**

* Implementation follows the same pattern as other technologies (PHP, Nginx, etc.)


## Implementation Plan

Implementation is complete:

- Scenarios: `docs/features/dotnet-logging.feature` (explicit, concrete, and robust)
- Tests: `tests/dotnet-config.tftest.hcl` (full coverage)
- Implementation: `dotnet-config.tf` (parsers, filters, maps)
- Documentation: README and ADRs updated

**Related:**
- ADR-0002 - Parser-Filter Architecture
- dotnet-config.tf implementation

**Common .NET Logging Frameworks:**

**Serilog (most popular):**
```csharp
Log.Logger = new LoggerConfiguration()
  .WriteTo.Console(new JsonFormatter())
  .CreateLogger();

Log.Information("User {UserId} logged in", userId);
// Output: {"@t":"2026-01-22T10:30:45Z","@mt":"User {UserId} logged in","UserId":123}
```

**Microsoft.Extensions.Logging:**
```csharp
builder.Logging.AddJsonConsole();
// Output: {"Timestamp":"2026-01-22T10:30:45Z","Level":"Information","Message":"User logged in"}
```
