Feature: Nginx JSON Log Parsing
  As a Platform Engineer
  I want to parse Nginx logs in JSON format (including ISO 8601 and legacy time formats)
  So that access logs are correctly processed and enriched

  Background:
    Given the Fluent Bit configuration module uses the parser-filter architecture (ADR-0002)
    And Nginx logs must be in JSON format (ISO 8601 or legacy time format)

  Scenario: Parse JSON access log (ISO 8601)
    Given a log in JSON format with time_local field in ISO 8601 format
    When the parser_config is generated
    Then the parser "nginx_json_iso8601" is present and matches the log

  Scenario: Parse JSON access log (legacy)
    Given a log in JSON format with time_local field in legacy format
    When the parser_config is generated
    Then the parser "nginx_json" is present and matches the log

  Scenario: Add log_source metadata
    When the filters_config is generated
    Then a modify filter adds the field log_source="nginx"

  Scenario: Container-specific routing
    Given log_sources includes a container name
    When the filters_config is generated
    Then the match pattern includes the container name
