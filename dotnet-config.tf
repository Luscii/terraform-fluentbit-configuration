locals {
  # .NET parser configurations
  dotnet_parsers = [
    {
      name   = "dotnet_text"
      format = "regex"
      regex  = "^(?<level>\\w+): (?<category>[\\w\\.]+)\\[(?<event_id>\\d+)\\]\\s+(?<message>.*)$"
      types = {
        level    = "string"
        category = "string"
        event_id = "string"
        message  = "string"
      }
    },
    {
      name   = "dotnet_json"
      format = "json"
    },
    {
      name   = "dotnet_serilog"
      format = "json"
    }
  ]

  # .NET filter configurations
  dotnet_filters = [
    # 1. Grep filter: exclude health checks/static assets
    {
      name  = "grep_health_check"
      type  = "grep"
      match = "kubernetes.var.log.containers.dotnet-app*"
      exclude = [
        { key = "message", pattern = ".*health.*|.*static.*" }
      ]
    },
    # 2. Grep filter: exclude profile image warnings
    {
      name  = "grep_profile_warning"
      type  = "grep"
      match = "kubernetes.var.log.containers.dotnet-app*"
      exclude = [
        { key = "message", pattern = ".*Image not found for userId.*" }
      ]
    },
    # 3. Modify filter: enrich with log_source
    {
      name  = "modify"
      type  = "modify"
      match = "kubernetes.var.log.containers.dotnet-app*"
      add_fields = {
        log_source = "dotnet"
      }
    },
    # 4. Loglevel filter: drop debug/trace
    {
      name  = "loglevel_drop_debug"
      type  = "grep"
      match = "kubernetes.var.log.containers.dotnet-app*"
      exclude = [
        { key = "level", pattern = "debug|trace" }
      ]
    },
    # 5. Loglevel filter: allow info/warn/error
    {
      name  = "loglevel_allow_info_warn_error"
      type  = "grep"
      match = "kubernetes.var.log.containers.dotnet-app*"
      regex = { key = "level", pattern = "info|warn|error|critical" }
    }
  ]

  # Map entry for this technology
  dotnet_parsers_map = {
    dotnet = local.dotnet_parsers
  }

  dotnet_filters_map = {
    dotnet = local.dotnet_filters
  }
}
