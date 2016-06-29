require_relative '../jdbc_spec_helper'

describe 'logstash-output-jdbc: derby', if: ENV['JDBC_DERBY_JAR'] do
  include_context 'rspec setup'
  include_context 'when initializing'
  include_context 'when outputting messages'

  let(:jdbc_jar_env) do
    'JDBC_DERBY_JAR'
  end

  let(:jdbc_create_table) do
    "CREATE table #{jdbc_test_table} (created_at timestamp not null, message varchar(512) not null)"
  end
 
  let(:jdbc_settings) do
    {
      'driver_class' => 'org.apache.derby.jdbc.EmbeddedDriver',
      'connection_string' => 'jdbc:derby:memory:testdb;create=true',
      'driver_jar_path' => ENV[jdbc_jar_env],
      'statement' => ['insert into logstash_output_jdbc_test (created_at, message) values(?, ?)', '@timestamp', 'message'],
      'max_flush_exceptions' => 1
    }
  end
end
