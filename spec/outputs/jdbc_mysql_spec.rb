require_relative '../jdbc_spec_helper'

describe 'logstash-output-jdbc: mysql', if: ENV['JDBC_MYSQL_JAR'] do
  include_context 'rspec setup'
  include_context 'when outputting messages'

  let(:jdbc_jar_env) do
    'JDBC_MYSQL_JAR'
  end

  let(:systemd_database_service) do
    'mysql'
  end

  let(:jdbc_settings) do
    {
      'driver_class' => 'com.mysql.jdbc.Driver',
      'connection_string' => 'jdbc:mysql://localhost/logstash?user=logstash&password=logstash',
      'driver_jar_path' => ENV[jdbc_jar_env],
      'statement' => jdbc_statement,
      'max_flush_exceptions' => 1
    }
  end
end
