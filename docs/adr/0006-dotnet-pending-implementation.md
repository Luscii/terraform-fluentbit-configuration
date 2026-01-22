# .NET Logging Support - Pending Implementation

**Status:** proposed

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

The module has a placeholder for .NET logging support (`dotnet-config.tf`) but the implementation contains TODOs. .NET applications can use various logging frameworks:

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

**Proposed option:** "Wait for actual .NET application requirement", because implementing without a real use case may result in incorrect assumptions and wasted effort. When a .NET application is deployed, we can:

1. Analyze its actual log format
2. Implement appropriate parsers
3. Add necessary filters
4. Create comprehensive tests
5. Document the specific configuration

### Current Implementation

```terraform
locals {
  dotnet_parsers = []  # TODO: Add specific .NET parser configurations

  dotnet_filters = [
    {
      name  = "modify"
      match = "*"
      add_fields = {
        log_source = "dotnet"
      }
    }
  ]

  dotnet_parsers_map = {
    dotnet = local.dotnet_parsers
  }

  dotnet_filters_map = {
    dotnet = local.dotnet_filters
  }
}
```

### Placeholder Status

The current implementation:
- ✅ Follows the parser-filter architecture pattern
- ✅ Has modify filter for metadata enrichment
- ❌ Has no parsers (empty list)
- ❌ Cannot parse any .NET log formats
- ⚠️ Will accept "dotnet" in log_sources but won't parse logs

### Consequences

**Positive (waiting):**

* Avoid premature optimization
* Implementation based on real requirements
* No maintenance burden for unused code
* Can tailor parsers to actual log format
* Ensures tests reflect real usage

**Negative (waiting):**

* Module advertises .NET support but doesn't deliver
* Need to implement when first .NET app deploys
* Could delay .NET application deployment

**Neutral:**

* Framework follows pattern (easy to add when needed)
* Metadata filter already in place

### When to Implement

Implement .NET parsers when:
1. First .NET application is planned for ECS Fargate
2. Logging framework and format are known
3. Sample logs are available for parser development
4. Time is available to implement and test properly

### Proposed Implementation Approach

When implemented, likely structure:

**Parsers:**
- `dotnet_json` - For JSON-formatted logs (Serilog, M.E.Logging with JSON formatter)
- `dotnet_plain` - For plain text logs (regex-based)
- `dotnet_<framework>` - Framework-specific if needed

**Filters:**
- Keep existing modify filter (log_source = "dotnet")
- Add grep filters for noise reduction if needed
- Add parsing filters for log levels, correlation IDs, etc.

## Implementation Plan

### Immediate Actions

**1. documentation-specialist** - Update documentation:
- Add notice in README.md that .NET support is placeholder
- Document that implementation pending actual requirement
- Explain what users should do if they need .NET support

**2. No other agents needed** - Wait for requirement

### Future Implementation (when needed)

**1. scenario-shaper** - Create scenario:
- File: `docs/features/dotnet-logging.feature`
- Based on actual .NET application log format

**2. terraform-tester** - Create tests:
- File: `tests/dotnet-config.tftest.hcl`
- Test actual parser configurations

**3. terraform-module-specialist** - Implement parsers:
- Replace TODO in dotnet-config.tf
- Add appropriate parsers for chosen framework
- Add filters as needed

**4. documentation-specialist** - Update docs:
- Document .NET logging configuration
- Provide setup examples for chosen framework

**5. examples-specialist** - Add examples:
- Add .NET example based on real configuration

## More Information

**Current Files:**
- dotnet-config.tf ⚠️ (placeholder with TODOs)
- Tests: ❌ Missing (no tests needed until implementation)
- Scenarios: ❌ Missing (no scenarios until implementation)
- Examples: ❌ Missing (no examples until implementation)

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

**Next Steps:**
1. Mark .NET support as "coming soon" in documentation
2. Wait for actual .NET application requirement
3. Implement based on real use case
4. Update this ADR to "accepted" when implemented
