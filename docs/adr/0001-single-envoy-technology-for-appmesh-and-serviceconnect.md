# Use Single Envoy Technology for Both AppMesh and ServiceConnect

**Status:** accepted

**Date:** 2026-01-22

**Deciders:** Platform Team

## Context and Problem Statement

The Luscii platform uses Envoy proxy in two deployment scenarios on AWS ECS Fargate:
1. **AWS App Mesh (legacy/deprecated)** - Service mesh using Envoy as sidecar
2. **AWS ECS Service Connect** - Native ECS service discovery using Envoy

We need to implement Fluent Bit parser and filter configurations for Envoy logs. The question is whether to create separate technology configurations (`appmesh` and `serviceconnect`) or use a single `envoy` configuration.

## Decision Drivers

* Both AppMesh and ServiceConnect use the same Envoy proxy version
* Log formats are identical (Envoy JSON access logs)
* AppMesh is deprecated and will be phased out
* Module simplicity and maintainability
* User experience and ease of use
* Container-level differentiation is already supported via `container` parameter

## Considered Options

* **Option 1**: Single `envoy` technology configuration
* **Option 2**: Separate `appmesh` and `serviceconnect` technologies

## Decision Outcome

**Chosen option:** "Single `envoy` technology configuration", because both deployment types use identical Envoy log formats and the existing `container` parameter provides sufficient differentiation when needed.

### Consequences

**Positive:**

* Simpler module structure with less code to maintain
* Single source of truth for Envoy log parsing
* Easier migration path from AppMesh to ServiceConnect (no configuration changes needed)
* Consistent with other technology configurations (php, nginx don't have deployment-specific variants)
* Less cognitive load for users
* Container-level filtering already supported via `container` parameter

**Negative:**

* No explicit distinction in technology name between AppMesh and ServiceConnect
* Cannot have deployment-specific filters (though none are currently needed)

**Neutral:**

* Users can use `container` parameter to distinguish between different Envoy sidecars when needed
* During migration, both can coexist using different container names

### Confirmation

Success confirmed when:
* Envoy JSON access logs are correctly parsed for both AppMesh and ServiceConnect deployments
* Health check endpoints are filtered out
* log_source metadata is added
* Tests pass with `terraform test`
* Documentation clearly explains single technology approach

## Pros and Cons of the Options

### Single `envoy` Technology

**Pros:**

* Identical log format means no need for separate parsers
* Simpler codebase and maintenance
* Container parameter provides differentiation when needed
* Easier migration from AppMesh to ServiceConnect
* Consistent with module patterns (other technologies don't have variants)
* Less duplication

**Cons:**

* No explicit technology name showing deployment type
* Cannot have deployment-specific filters (not currently needed)

### Separate `appmesh` and `serviceconnect` Technologies

**Pros:**

* Explicit about deployment type in configuration
* Could have deployment-specific filters if needed in future
* Clear separation of concerns

**Cons:**

* Code duplication (identical parsers and filters)
* More complex module structure
* Harder to maintain two identical configurations
* Complicates migration (need to change technology name)
* Users must remember which technology to use
* Inconsistent with other technology patterns in module

## Implementation Details

### Parser Configuration

```hcl
envoy_parsers = [
  {
    name        = "envoy_json_access"
    format      = "json"
    time_key    = "start_time"
    time_format = "%Y-%m-%dT%H:%M:%S.%LZ"
    time_keep   = false
    filter = {
      match        = "*"
      key_name     = "log"
      reserve_data = true
      preserve_key = false
      unescape_key = false
    }
  }
]
```

### Filter Configuration

```hcl
envoy_filters = [
  # Health check exclusions
  { name = "grep", match = "*", exclude = "path /health" },
  { name = "grep", match = "*", exclude = "path /ready" },
  { name = "grep", match = "*", exclude = "path /livez" },
  { name = "grep", match = "*", exclude = "path /readyz" },
  # Metadata enrichment
  { name = "modify", match = "*", add_fields = { log_source = "envoy" } }
]
```

### Usage Examples

**ServiceConnect (recommended):**
```hcl
log_sources = [
  { name = "envoy", container = "service-connect" }
]
```

**AppMesh (legacy):**
```hcl
log_sources = [
  { name = "envoy", container = "envoy" }
]
```

**Migration scenario (both in same task):**
```hcl
log_sources = [
  { name = "envoy", container = "appmesh-envoy" },
  { name = "envoy", container = "service-connect-envoy" }
]
```

## More Information

* Envoy access log format: https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage
* AWS App Mesh Envoy: https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html
* ECS Service Connect: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html
* Related implementation: `envoy-config.tf`
* Test file: `tests/envoy-config.tftest.hcl`
