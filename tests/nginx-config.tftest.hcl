# Nginx Configuration Tests
# Tests for nginx-config.tf to validate parser and filter configurations

variables {
  name = "test-nginx"
  log_sources = [
    {
      name      = "nginx"
      container = "web"
    }
  ]
}

# Test: Nginx parsers are defined correctly
run "validate_nginx_parsers_count" {
  command = plan
  assert {
    condition     = length(local.nginx_parsers) == 2
    error_message = "Expected 2 Nginx parsers (iso8601, json), got ${length(local.nginx_parsers)}"
  }
}

run "validate_nginx_json_iso8601_parser" {
  command = plan
  assert {
    condition     = local.nginx_parsers[0].name == "nginx_json_iso8601"
    error_message = "First parser should be nginx_json_iso8601"
  }
  assert {
    condition     = local.nginx_parsers[0].format == "json"
    error_message = "nginx_json_iso8601 parser should use json format"
  }
  assert {
    condition     = local.nginx_parsers[0].time_key == "time_local"
    error_message = "nginx_json_iso8601 parser should use time_local as time_key"
  }
}

run "validate_nginx_json_parser" {
  command = plan
  assert {
    condition     = local.nginx_parsers[1].name == "nginx_json"
    error_message = "Second parser should be nginx_json"
  }
  assert {
    condition     = local.nginx_parsers[1].format == "json"
    error_message = "nginx_json parser should use json format"
  }
  assert {
    condition     = local.nginx_parsers[1].time_key == "time_local"
    error_message = "nginx_json parser should use time_local as time_key"
  }
}


run "validate_nginx_filters_count" {
  command = plan
  assert {
    condition     = length(local.nginx_filters) == 1
    error_message = "Expected 1 Nginx filter (modify), got ${length(local.nginx_filters)}"
  }
}

run "validate_nginx_modify_filter" {
  command = plan
  assert {
    condition     = local.nginx_filters[0].name == "modify"
    error_message = "Nginx filter should be modify"
  }
  assert {
    condition     = local.nginx_filters[0].add_fields.log_source == "nginx"
    error_message = "modify filter should add log_source=nginx"
  }
}

run "validate_nginx_parsers_map" {
  command = plan
  assert {
    condition     = contains(keys(local.nginx_parsers_map), "nginx")
    error_message = "nginx_parsers_map should contain 'nginx' key"
  }
  assert {
    condition     = length(local.nginx_parsers_map["nginx"]) == 2
    error_message = "nginx_parsers_map['nginx'] should contain 2 parsers"
  }
}

run "validate_nginx_filters_map" {
  command = plan
  assert {
    condition     = contains(keys(local.nginx_filters_map), "nginx")
    error_message = "nginx_filters_map should contain 'nginx' key"
  }
  assert {
    condition     = length(local.nginx_filters_map["nginx"]) == 1
    error_message = "nginx_filters_map['nginx'] should contain 1 filter"
  }
}

run "validate_container_specific_match" {
  command = plan
  assert {
    condition     = local.technology_filters[0].match == "web-firelens-*"
    error_message = "Filter match pattern should use FireLens tag format: <container-name>-firelens-*"
  }
}
