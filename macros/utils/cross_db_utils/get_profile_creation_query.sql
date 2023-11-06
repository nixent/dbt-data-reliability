{% macro get_profile_creation_query(parameters) %}
  {% do return(adapter.dispatch("get_profile_creation_query", "elementary")(parameters)) %}
{% endmacro %}


{% macro snowflake__get_profile_creation_query(parameters) %}
{%- set schema_tuples = elementary.get_configured_schemas_from_graph() -%}
{%- set databases = schema_tuples | map(attribute=0) | unique %}
CREATE OR REPLACE USER {{ parameters["user"] }} PASSWORD = '{{ parameters["password"] }}';
CREATE OR REPLACE ROLE {{ parameters["role"] }};
GRANT ROLE {{ parameters["role"] }} TO USER {{ parameters["user"] }};
GRANT USAGE ON WAREHOUSE {{ parameters["warehouse"] }} TO ROLE {{ parameters["role"] }};
{% for database in databases -%}
GRANT USAGE,MONITOR ON DATABASE {{ database }} TO ROLE {{ parameters["role"] }};
{%- endfor %}
{% for schema_tuple in schema_tuples -%}
GRANT USAGE,MONITOR ON SCHEMA {{ schema_tuple[0] }}.{{ schema_tuple[1] }} TO ROLE {{ parameters["role"] }};
{%- endfor %}

// Data access to elementary schema
GRANT SELECT ON ALL TABLES IN SCHEMA {{ parameters["database"] }}.{{ parameters["schema"] }} TO ROLE {{ parameters["role"] }};
GRANT SELECT ON FUTURE TABLES IN SCHEMA {{ parameters["database"] }}.{{ parameters["schema"] }} TO ROLE {{ parameters["role"] }};
GRANT SELECT ON ALL VIEWS IN SCHEMA {{ parameters["database"] }}.{{ parameters["schema"] }} TO ROLE {{ parameters["role"] }};
GRANT SELECT ON FUTURE VIEWS IN SCHEMA {{ parameters["database"] }}.{{ parameters["schema"] }} TO ROLE {{ parameters["role"] }};

// Metadata access to rest of dbt project
{% for database, schema in schema_tuples -%}
GRANT REFERENCES ON ALL TABLES IN SCHEMA {{ database }}.{{ schema }} TO ROLE {{ parameters["role"] }};
GRANT REFERENCES ON FUTURE TABLES IN SCHEMA {{ database }}.{{ schema }} TO ROLE {{ parameters["role"] }};
GRANT REFERENCES ON ALL VIEWS IN SCHEMA {{ database }}.{{ schema }} TO ROLE {{ parameters["role"] }};
GRANT REFERENCES ON FUTURE VIEWS IN SCHEMA {{ database }}.{{ schema }} TO ROLE {{ parameters["role"] }};
{% endfor -%}
{% endmacro %}


{% macro postgres__get_profile_creation_query(parameters) %}
CREATE USER {{ parameters["user"] }} WITH PASSWORD '{{ parameters["password"] }}';
GRANT USAGE ON SCHEMA {{ parameters["schema"] }} TO {{ parameters["user"] }};
GRANT SELECT ON ALL TABLES IN SCHEMA {{ parameters["schema"] }} TO {{ parameters["user"] }};
ALTER DEFAULT PRIVILEGES IN SCHEMA {{ parameters["schema"] }} GRANT SELECT ON TABLES TO {{ parameters["user"] }};
{% endmacro %}


{# Databricks, BigQuery, Spark #}
{% macro default__get_profile_creation_query(parameters) %}
  {% do exceptions.raise_compiler_error('User creation not supported through sql using ' ~ target.type) %}
{% endmacro %}
