# Test file for Envoy parser and filter configurations
# Tests validate the Envoy JSON access log parser and filters for both AppMesh and ServiceConnect deployments

variables {
  name = "test-envoy"
  log_sources = [
    {
      name      = "envoy"
      container = "envoy"
    }
  ]
}

# Test: Envoy parsers exist and have correct structure
run "validate_envoy_parsers_exist" {
  command = plan

  assert {
    condition     = length(local.envoy_parsers) > 0
    error_message = "Envoy parsers should be defined"
  }
}

# Test: Envoy JSON access log parser
run "validate_envoy_json_access_parser" {
  command = plan

  assert {
    condition     = local.envoy_parsers[0].name == "envoy_json_access"
    error_message = "First parser should be envoy_json_access"
  }

  assert {
    condition     = local.envoy_parsers[0].format == "json"
    error_message = "envoy_json_access should use json format"
  }

  assert {
    condition     = local.envoy_parsers[0].time_key == "start_time"
    error_message = "envoy_json_access should use 'start_time' as time_key"
  }

  assert {
    condition     = local.envoy_parsers[0].time_format == "%Y-%m-%dT%H:%M:%S.%LZ"
    error_message = "envoy_json_access should use ISO 8601 format with milliseconds: %Y-%m-%dT%H:%M:%S.%LZ"
  }

  assert {
    condition     = local.envoy_parsers[0].time_keep == false
    error_message = "envoy_json_access should not keep original time field"
  }
}

# Test: Envoy parser has filter configuration
run "validate_envoy_parser_filter" {
  command = plan

  assert {
    condition     = local.envoy_parsers[0].filter != null
    error_message = "envoy_json_access parser should have filter configuration"
  }

  assert {
    condition     = local.envoy_parsers[0].filter.match == "*"
    error_message = "Parser filter should match '*' (to be overridden by container pattern)"
  }

  assert {
    condition     = local.envoy_parsers[0].filter.key_name == "log"
    error_message = "Parser filter should parse 'log' field"
  }

  assert {
    condition     = local.envoy_parsers[0].filter.reserve_data == true
    error_message = "Parser filter should reserve data"
  }

  assert {
    condition     = local.envoy_parsers[0].filter.preserve_key == false
    error_message = "Parser filter should not preserve original key after parsing"
  }

  assert {
    condition     = local.envoy_parsers[0].filter.unescape_key == false
    error_message = "Parser filter should not unescape key"
  }
}

# Test: Envoy filters exist
run "validate_envoy_filters_exist" {
  command = plan

  assert {
    condition     = length(local.envoy_filters) > 0
    error_message = "Envoy filters should be defined"
  }
}

# Test: Health check exclusion filters
run "validate_health_check_exclusions" {
  command = plan

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "grep" && can(regex("/health", f.exclude))]) >= 1
    error_message = "Should have grep filter excluding /health endpoint"
  }

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "grep" && can(regex("/ready", f.exclude))]) >= 1
    error_message = "Should have grep filter excluding /ready endpoint"
  }

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "grep" && can(regex("/livez", f.exclude))]) >= 1
    error_message = "Should have grep filter excluding /livez endpoint"
  }

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "grep" && can(regex("/readyz", f.exclude))]) >= 1
    error_message = "Should have grep filter excluding /readyz endpoint"
  }
}

# Test: All grep filters should have exclude patterns
run "validate_grep_filters_structure" {
  command = plan

  assert {
    condition     = alltrue([for f in local.envoy_filters : contains(keys(f), "exclude") if f.name == "grep"])
    error_message = "All grep filters should have exclude pattern"
  }

  assert {
    condition     = alltrue([for f in local.envoy_filters : f.match == "*" if f.name == "grep"])
    error_message = "All grep filters should match '*' (to be overridden by container pattern)"
  }
}

# Test: Modify filter adds log_source
run "validate_modify_filter" {
  command = plan

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "modify"]) == 1
    error_message = "Expected exactly 1 modify filter"
  }

  assert {
    condition     = length([for f in local.envoy_filters : f if f.name == "modify" && try(f.add_fields.log_source == "envoy", false)]) == 1
    error_message = "Modify filter should add log_source='envoy'"
  }

  assert {
    condition     = [for f in local.envoy_filters : f if f.name == "modify"][0].match == "*"
    error_message = "Modify filter should match '*' (to be overridden by container pattern)"
  }
}

# Test: Envoy maps are created correctly
run "validate_envoy_maps" {
  command = plan

  assert {
    condition     = contains(keys(local.envoy_parsers_map), "envoy")
    error_message = "envoy_parsers_map should contain 'envoy' key"
  }

  assert {
    condition     = local.envoy_parsers_map["envoy"] == local.envoy_parsers
    error_message = "envoy_parsers_map['envoy'] should reference local.envoy_parsers"
  }

  assert {
    condition     = contains(keys(local.envoy_filters_map), "envoy")
    error_message = "envoy_filters_map should contain 'envoy' key"
  }

  assert {
    condition     = local.envoy_filters_map["envoy"] == local.envoy_filters
    error_message = "envoy_filters_map['envoy'] should reference local.envoy_filters"
  }
}

# Test: Integration - Envoy in log sources produces correct output
run "validate_envoy_integration" {
  command = plan

  variables {
    log_sources = [
      {
        name      = "envoy"
        container = "service-connect"
      }
    ]
  }

  assert {
    condition     = length(local.parser_config) > 0
    error_message = "Parser config should contain envoy parsers"
  }

  assert {
    condition     = length(local.filters_config) > 0
    error_message = "Filters config should contain envoy filters"
  }
}

# Test: Multiple Envoy containers (AppMesh + ServiceConnect scenario)
run "validate_multiple_envoy_containers" {
  command = plan

  variables {
    log_sources = [
      {
        name      = "envoy"
        container = "appmesh-envoy"
      },
      {
        name      = "envoy"
        container = "service-connect"
      }
    ]
  }

  assert {
    condition     = length([for s in var.log_sources : s if s.name == "envoy"]) == 2
    error_message = "Should support multiple envoy containers"
  }

  assert {
    condition     = length(local.filters_config) > 0
    error_message = "Should generate filters for multiple envoy containers"
  }
}
