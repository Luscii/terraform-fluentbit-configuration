---
applyTo: "outputs.tf"
---
This Terraform module needs to be used in conjunction with the [Luscii/terraform-aws-ecs-fargate-datadog-container-definitions](https://github.com/Luscii/terraform-aws-ecs-fargate-datadog-container-definitions). It contains the necessary custom Fluentbit configuration to forward logs through Fluentbit.

The outputs provided by this module should be used as the following variables in the `Luscii/terraform-aws-ecs-fargate-datadog-container-definitions` module:
- `log_config_parsers` - https://github.com/Luscii/terraform-aws-ecs-fargate-datadog-container-definitions/blob/main/variables.tf#L472-L526
- `log_config_filters` - https://github.com/Luscii/terraform-aws-ecs-fargate-datadog-container-definitions/blob/main/variables.tf#L528-L579

Note that the permalinks for these outputs may change if the Fluentbit configuration in this module is updated. Always refer to the latest version of this module to ensure compatibility.

The variables are based on the Fluentbit configuration which is documented here:
- [Parsers](https://docs.fluentbit.io/manual/data-pipeline/parsers)
- [Filters](https://docs.fluentbit.io/manual/data-pipeline/filters)

The parsers variable also includes a filter which will result in a filter being added to the Filters section, this is done in the `local.all_filters` defined on: https://github.com/Luscii/terraform-aws-ecs-fargate-datadog-container-definitions/blob/main/logging-custom-config.tf#L7-L22.
Make sure to review the Fluentbit documentation for more details on how to customize and extend the logging configuration as needed.

## Luscii/terraform-aws-ecs-fargate-datadog-container-definitions
The `Luscii/terraform-aws-ecs-fargate-datadog-container-definitions` module provides a way to define ECS Fargate tasks with Datadog capabilities. It sets up the necessary container definitions, logging configurations, and integrations with Datadog for monitoring and observability.

### Parsers input variable
The parser input variable in the `Luscii/terraform-aws-ecs-fargate-datadog-container-definitions` module has the following structure in `v0.1.8`:
```hcl
variable "log_config_parsers" {
  description = "Custom parser definitions for Fluent Bit log processing. Each parser can extract and transform log data using formats like json, regex, ltsv, or logfmt. The optional filter section controls when and how the parser is applied to log records. Required for Fluent Bit v3.x YAML configurations. See: https://docs.fluentbit.io/manual/data-pipeline/parsers/configuring-parser and https://docs.fluentbit.io/manual/pipeline/filters/parser"
  type = list(object({
    name   = string
    format = string
    # JSON parser options
    time_key    = optional(string)
    time_format = optional(string)
    time_keep   = optional(bool)
    # Regex parser options
    regex = optional(string)
    # LTSV parser options (tab-separated values)
    # Logfmt parser options
    # Decoder options
    decode_field    = optional(string)
    decode_field_as = optional(string)
    # Type casting
    types = optional(string)
    # Additional options
    skip_empty_values = optional(bool)
    # Filter configuration - controls when and how this parser is applied
    filter = optional(object({
      match        = optional(string)      # Tag pattern to match (e.g., 'docker.*', 'app.logs')
      key_name     = optional(string)      # Field name to parse (e.g., 'log', 'message')
      reserve_data = optional(bool, false) # Preserve all other fields in the record
      preserve_key = optional(bool, false) # Keep the original key field after parsing
      unescape_key = optional(bool, false) # Unescape the key field before parsing
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for parser in var.log_config_parsers :
      contains(["json", "regex", "ltsv", "logfmt"], parser.format)
    ])
    error_message = "Parser format must be one of: json, regex, ltsv, logfmt"
  }

  validation {
    condition = alltrue([
      for parser in var.log_config_parsers :
      parser.format != "regex" || parser.regex != null
    ])
    error_message = "Regex parser requires 'regex' field to be set"
  }

  validation {
    condition = alltrue([
      for parser in var.log_config_parsers :
      parser.filter == null || parser.filter.key_name != null
    ])
    error_message = "When filter is specified, 'key_name' is required to identify which field to parse"
  }
}
```

### Filters input variable
The filters input variable in the `Luscii/terraform-aws-ecs-fargate-datadog-container-definitions` module has the following structure in `v0.1.8`:
```hcl
variable "log_config_filters" {
  description = "Custom filter definitions for Fluent Bit log processing. Filters can modify, enrich, or drop log records. Common filter types include grep (include/exclude), modify (add/rename/remove fields), nest (restructure data), and kubernetes (enrich with K8s metadata). See: https://docs.fluentbit.io/manual/pipeline/filters"
  type = list(object({
    name  = string
    match = optional(string) # Tag pattern to match (e.g., 'docker.*', 'app.logs')
    # Parser filter options
    parser       = optional(string)      # Parser name to apply
    key_name     = optional(string)      # Field name to parse (required for parser filter)
    reserve_data = optional(bool, false) # Preserve all other fields in the record
    preserve_key = optional(bool, false) # Keep the original key field after parsing
    unescape_key = optional(bool, false) # Unescape the key field before parsing
    # Grep filter options
    regex   = optional(string) # Regex pattern to match
    exclude = optional(string) # Regex pattern to exclude
    # Modify filter options
    add_fields    = optional(map(string))  # Fields to add
    rename_fields = optional(map(string))  # Fields to rename (old_name = new_name)
    remove_fields = optional(list(string)) # Fields to remove
    # Nest filter options
    operation     = optional(string)       # nest or lift
    wildcard      = optional(list(string)) # Wildcard patterns
    nest_under    = optional(string)       # Target field for nesting
    nested_under  = optional(string)       # Source field for lifting
    remove_prefix = optional(string)       # Prefix to remove from keys
    add_prefix    = optional(string)       # Prefix to add to keys
  }))
  default = []

  validation {
    condition = alltrue([
      for filter in var.log_config_filters :
      filter.name == "parser" ? filter.key_name != null : true
    ])
    error_message = "Parser filter requires 'key_name' to identify which field to parse"
  }

  validation {
    condition = alltrue([
      for filter in var.log_config_filters :
      filter.name == "parser" ? filter.parser != null : true
    ])
    error_message = "Parser filter requires 'parser' field to specify which parser to use"
  }

  validation {
    condition = alltrue([
      for filter in var.log_config_filters :
      filter.name == "nest" ? filter.operation != null : true
    ])
    error_message = "Nest filter requires 'operation' field (nest or lift)"
  }
}
```

## Example Output Structure

This module should provide outputs that match the variable structure above. Here's an example of what the outputs could look like:

### Example: JSON Parser with Filter
```hcl
output "parsers" {
  description = "Custom parser definitions for Fluent Bit log processing to be used in Luscii/terraform-aws-ecs-fargate-datadog-container-definitions"
  value = [
    {
      name   = "docker_json"
      format = "json"
      time_key    = "time"
      time_format = "%Y-%m-%dT%H:%M:%S.%LZ"
      time_keep   = false
      filter = {
        match        = "docker.*"
        key_name     = "log"
        reserve_data = true
        preserve_key = false
        unescape_key = false
      }
    }
  ]
}

output "filters" {
  description = "Custom filter definitions for Fluent Bit log processing to be used in Luscii/terraform-aws-ecs-fargate-datadog-container-definitions"
  value = [
    {
      name  = "modify"
      match = "docker.*"
      add_fields = {
        environment = "production"
        service     = "api"
      }
    },
    {
      name     = "grep"
      match    = "docker.*"
      regex    = "level (ERROR|WARN)"
      exclude  = null
    }
  ]
}
```

### Example: Regex Parser
```hcl
parsers = [
  {
    name   = "nginx_access"
    format = "regex"
    regex  = "^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^\\\"]*?)(?: +\\S*)?)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$"
    time_key    = "time"
    time_format = "%d/%b/%Y:%H:%M:%S %z"
    filter = {
      match        = "nginx.*"
      key_name     = "log"
      reserve_data = true
    }
  }
]
```

### Example: Nest Filter
```hcl
filters = [
  {
    name       = "nest"
    match      = "app.*"
    operation  = "nest"
    wildcard   = ["level", "message", "timestamp"]
    nest_under = "log_data"
    add_prefix = "original_"
  }
]
```
