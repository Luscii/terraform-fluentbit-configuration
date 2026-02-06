Feature: Node.js Pino Logging Support
  As a Platform Engineer
  I want robust parsing and filtering for Node.js Pino logs
  So that all timestamp variants are correctly processed and noise is filtered

  Background:
    Given the Fluent Bit configuration module uses the parser-filter architecture (ADR-0002)
    And Node.js Pino logs are emitted in JSON format with various timestamp formats
    And Pino supports milliseconds epoch and ISO 8601 timestamp formats

  Scenario: Parse Pino JSON with milliseconds epoch timestamp
    Given a log with time as milliseconds epoch "1738755000000"
    When the parser_config is generated
    Then the parser "nodejs_pino_json_epoch" is present and matches the log

  Scenario: Parse Pino JSON with ISO 8601 UTC timestamp
    Given a log with time "2026-02-05T10:30:00.000Z"
    When the parser_config is generated
    Then the parser "nodejs_pino_json_iso" is present and matches the log

  Scenario: Parse Pino JSON with ISO 8601 timestamp and timezone
    Given a log with time "2026-02-05T10:30:00.000+00:00"
    When the parser_config is generated
    Then the parser "nodejs_pino_json_iso_tz" is present and matches the log

  Scenario: Filter out health check endpoints
    Given a log containing health check endpoint patterns
    When the filters_config is generated
    Then a grep filter excludes health check logs

  Scenario: Filter out static asset requests
    Given a log containing static asset requests (.js, .css, .png, etc.)
    When the filters_config is generated
    Then a grep filter excludes static asset logs

  Scenario: Filter out debug logs
    Given a log with level 20 (debug)
    When the filters_config is generated
    Then a grep filter excludes debug level logs

  Scenario: Add log_source metadata
    When the filters_config is generated
    Then a modify filter adds the field log_source="nodejs"

  Scenario: Container-specific routing
    Given log_sources includes a container name "nodejs-app"
    When the filters_config is generated
    Then the match pattern is "nodejs-app-firelens-*"
