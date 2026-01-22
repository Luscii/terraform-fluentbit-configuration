Feature: Dotnet log parsing and filtering
  As a Platform Engineer
  I want to parse and filter dotnet service logs
  So that logs are correctly processed, enriched, and noise is reduced

  # Example log lines (context):
  #
  # Text log: info: Microsoft.AspNetCore.Hosting.Diagnostics[2]
  # Text log: Request finished HTTP/1.1 POST https://api.luscii.com/connect/token - 200 - application/json;+charset=UTF-8 18.4804ms
  # Text log: info: connect.images.Controllers.SvgImageController[0]      Getting SVG image with id ...
  # Text log: warn: connect.images.Controllers.UserProfileImagesController[0]      Image not found for userId ...
  # JSON log: {"Timestamp":"2026-01-22T10:30:45Z","Level":"Information","Message":"User logged in"}
  # Serilog:  {"@t":"2026-01-22T10:30:45Z","@mt":"User {UserId} logged in","UserId":123}

  Background:
    Given the Fluent Bit configuration module uses the parser-filter architecture (ADR-0002)
    And dotnet logs may be in text or JSON format


  Scenario: Parse text log line (level/category/event id)
    Given a dotnet log line "info: Microsoft.AspNetCore.Hosting.Diagnostics[2]"
    When the parser_config is generated
    Then the parser "dotnet_text" is present and matches the log

  Scenario: Parse request finished log line (extract HTTP info)
    Given a dotnet log line "Request finished HTTP/1.1 POST https://api.luscii.com/connect/token - 200 - application/json;+charset=UTF-8 18.4804ms"
    When the parser_config is generated
    Then the parser "dotnet_text" is present and extracts HTTP method and status code

  Scenario: Parse JSON log line (future-proof)
    Given a dotnet log line '{"Timestamp":"2026-01-22T10:30:45Z","Level":"Information","Message":"User logged in"}'
    When the parser_config is generated
    Then the parser "dotnet_json" is present and matches the log

  Scenario: Parse Serilog JSON log line (future-proof)
    Given a dotnet log line '{"@t":"2026-01-22T10:30:45Z","@mt":"User {UserId} logged in","UserId":123}'
    When the parser_config is generated
    Then the parser "dotnet_serilog" is present and matches the log

  Scenario: Add log_source metadata
    When the filters_config is generated
    Then a modify filter adds the field log_source="dotnet"

  Scenario: Filter out health check and static asset requests
    Given a dotnet log line "info: connect.images.Controllers.SvgImageController[0]      Getting SVG image with id ..."
    When the filters_config is generated
    Then a grep filter excludes this log

  Scenario: Filter out missing profile image warnings
    Given a dotnet log line "warn: connect.images.Controllers.UserProfileImagesController[0]      Image not found for userId ..."
    When the filters_config is generated
    Then a grep filter excludes this log

  Scenario: Container-specific routing
    Given log_sources includes a container name "dotnet-app"
    When the filters_config is generated
    Then the match pattern includes the container name "dotnet-app"

  Scenario Outline: Drop logs below minimum log level
    Given a dotnet log line with level <level>
    When the minimum log level is set to <min_level>
    Then the log is <included>
    Examples:
      | level | min_level | included  |
      | debug | info      | excluded  |
      | info  | info      | included  |
      | warn  | info      | included  |
      | trace | warn      | excluded  |
      | error | warn      | included  |
