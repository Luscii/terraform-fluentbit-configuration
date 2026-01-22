# Parser-Filter Architecture for Technology-Specific Log Processing

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

The Fluent Bit configuration module needs to support multiple application technologies (PHP, Nginx, Envoy, .NET, Datadog) running in ECS Fargate containers. Each technology produces logs in different formats and requires specific parsing and filtering logic. We need a scalable, maintainable architecture that:

- Supports multiple log formats from different technologies
- Allows technology-specific parser and filter configurations
- Enables container-specific log routing when needed
- Provides sensible defaults while allowing customization
- Maintains clear separation of concerns

## Decision Drivers

* Must support at least 5 different technologies (PHP, Nginx, Envoy, .NET, Datadog)
* Must handle technology-specific log formats (JSON, regex, custom)
* Must allow filtering based on container name for multi-container tasks
* Must be extensible for future technologies
* Must avoid code duplication across technologies
* Must integrate with terraform-aws-ecs-fargate-datadog-container-definitions module
* Must provide clear, maintainable code structure

## Considered Options

* Monolithic configuration with all parsers/filters in one file
* Technology-specific modules (separate terraform modules per technology)
* **Technology-specific config files with centralized aggregation** (chosen)
* External configuration files (YAML/JSON)

## Decision Outcome

**Chosen option:** "Technology-specific config files with centralized aggregation", because it provides the best balance of separation of concerns, maintainability, and extensibility while keeping all configuration in Terraform code.

### Architecture Pattern

**File Structure:**
```
config.tf           # Central aggregation logic
php-config.tf       # PHP parsers and filters
nginx-config.tf     # Nginx parsers and filters
envoy-config.tf     # Envoy parsers and filters
dotnet-config.tf    # .NET parsers and filters
datadog-config.tf   # Datadog parsers and filters
main.tf             # Module label
variables.tf        # Input variables
outputs.tf          # Module outputs
```

**Each technology config file contains:**
1. `{tech}_parsers` - List of parser configurations
2. `{tech}_filters` - List of filter configurations
3. `{tech}_parsers_map` - Map entry for technology lookup
4. `{tech}_filters_map` - Map entry for technology lookup

**Central aggregation (config.tf):**
1. Merges all technology parser maps
2. Merges all technology filter maps
3. Applies container-specific match patterns
4. Combines with custom parsers/filters from variables
5. Outputs final parser_config and filters_config

### Data Flow

```
User Input (var.log_sources)
  → Technology lookup in merged maps
  → Technology-specific parsers + filters
  → Container match pattern application
  → Merge with custom parsers/filters
  → Output to container definition module
```

### Consequences

**Positive:**

* Clear separation of concerns - each technology in own file
* Easy to add new technologies - create new {tech}-config.tf
* Maintainable - technology-specific logic is isolated
* Extensible - can override with custom parsers/filters
* Type-safe - Terraform validates structure
* No code duplication - shared logic in config.tf
* Easy to test - can test each technology independently
* Git-friendly - changes to one technology don't affect others

**Negative:**

* More files to manage (one per technology)
* Need to update config.tf when adding new technology (add to merge())
* Technology names are hardcoded in validation
* Cannot dynamically discover technologies

**Neutral:**

* All configuration remains in Terraform (not external files)
* Each technology must follow the same parser/filter structure
* Container matching pattern is applied uniformly

### Confirmation

Success confirmed by:
* All 5 technologies successfully implemented
* Tests pass for PHP and Envoy configurations
* Module successfully integrates with ecs-fargate-datadog-container-definitions
* Easy addition of Envoy configuration (ADR-0001) proved extensibility

## Pros and Cons of the Options

### Monolithic Configuration

Single file with all parsers and filters.

**Pros:**
* Simple - everything in one place
* No need to manage multiple files
* Easy to search all configurations

**Cons:**
* Large file becomes unmaintainable (>1000 lines)
* Changes to one technology risk breaking others
* Difficult to understand structure
* Merge conflicts more likely
* Hard to test individual technologies
* Poor separation of concerns

### Technology-Specific Modules

Separate Terraform module for each technology.

**Pros:**
* Complete isolation between technologies
* Can version technologies independently
* Ultimate separation of concerns
* Reusable across projects

**Cons:**
* Over-engineered for this use case
* Harder to maintain (multiple repositories or module versions)
* More complex module calls
* Doesn't reduce code significantly
* Adds indirection and complexity
* Module composition overhead

### External Configuration Files

Use YAML/JSON files for parser/filter definitions.

**Pros:**
* Non-Terraform users can contribute
* Potentially simpler syntax
* Could enable runtime configuration

**Cons:**
* Loses Terraform type safety
* Two languages to maintain (HCL + YAML/JSON)
* Harder to validate
* File loading complexity
* No Terraform plan preview of changes
* External file management in deployments

## Implementation Plan

### Agent Coordination

**1. scenario-shaper** - Create Gherkin scenarios for each technology:
- `docs/features/php-logging.feature`
- `docs/features/nginx-logging.feature`
- `docs/features/datadog-logging.feature`
- `docs/features/dotnet-logging.feature`
- `docs/features/module-architecture.feature`

**2. terraform-tester** - Create missing test files:
- `tests/nginx-config.tftest.hcl`
- `tests/datadog-config.tftest.hcl`
- `tests/dotnet-config.tftest.hcl` (after .NET implementation)
- `tests/config.tftest.hcl` (integration tests)

**3. terraform-module-specialist** - Complete .NET implementation:
- Replace TODOs in `dotnet-config.tf`
- Implement .NET-specific parsers (JSON format expected)
- Implement .NET-specific filters

**4. documentation-specialist** - Update documentation:
- Complete README.md with all technologies
- Add usage examples for each technology
- Document parser/filter structure
- Add architecture overview

**5. examples-specialist** - Enhance examples:
- Add technology-specific examples in examples/
- Show multi-technology scenarios
- Demonstrate custom parser/filter usage

## More Information

**Related Files:**
- `config.tf` - Central aggregation logic
- `php-config.tf` - PHP implementation (reference)
- `envoy-config.tf` - Envoy implementation (reference)
- `variables.tf` - log_sources, custom_parsers, custom_filters
- `outputs.tf` - parser_config, filters_config

**Related ADRs:**
- [ADR-0001](0001-single-envoy-technology-for-appmesh-and-serviceconnect.md) - Single Envoy technology (example of extensibility)

**Dependencies:**
- CloudPosse label module v0.25.0
- Consumer: terraform-aws-ecs-fargate-datadog-container-definitions

**Testing:**
- php-config.tftest.hcl ✅ (29 tests passing)
- envoy-config.tftest.hcl ✅ (10 tests passing)
- nginx-config.tftest.hcl ❌ (missing)
- datadog-config.tftest.hcl ❌ (missing)
- dotnet-config.tftest.hcl ❌ (missing)
- config.tftest.hcl ❌ (missing - integration tests)
