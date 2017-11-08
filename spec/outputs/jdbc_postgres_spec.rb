require_relative '../jdbc_spec_helper'

describe 'logstash-output-jdbc: postgres', if: ENV['JDBC_POSTGRES_JAR'] do
  include_context 'rspec setup'
  include_context 'when outputting messages'

  let(:jdbc_jar_env) do
    'JDBC_POSTGRES_JAR'
  end

  # TODO: Postgres doesnt kill connections fast enough for the test to pass
  # Investigate options.

  #let(:systemd_database_service) do
  #  'postgresql'
  #end

  let(:jdbc_statement_fields) do
    [
      {db_field: "created_at",       db_type: "timestamp",     db_value: 'CAST(? as timestamp)',  event_field: '@timestamp'},
      {db_field: "message",          db_type: "varchar(512)",  db_value: '?',                     event_field: 'message'},
      {db_field: "message_sprintf",  db_type: "varchar(512)",  db_value: '?',                     event_field: 'sprintf-%{message}'},
      {db_field: "static_int",       db_type: "int",           db_value: '?',                     event_field: 'int'},
      {db_field: "static_bigint",    db_type: "bigint",        db_value: '?',                     event_field: 'bigint'},
      {db_field: "static_float",     db_type: "float",         db_value: '?',                     event_field: 'float'},
      {db_field: "static_bool",      db_type: "boolean",       db_value: '?',                     event_field: 'bool'},
      {db_field: "static_bigdec",    db_type: "decimal",       db_value: '?',                     event_field: 'bigdec'}

    ]
  end

  let(:jdbc_settings) do
    {
      'driver_class' => 'org.postgresql.Driver',
      'connection_string' => 'jdbc:postgresql://localhost/logstash?user=logstash&password=logstash',
      'driver_jar_path' => ENV[jdbc_jar_env],
      'statement' => jdbc_statement,
      'max_flush_exceptions' => 1
    }
  end
end
