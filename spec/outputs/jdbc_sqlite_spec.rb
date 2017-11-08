require_relative '../jdbc_spec_helper'

describe 'logstash-output-jdbc: sqlite', if: ENV['JDBC_SQLITE_JAR'] do
  JDBC_SQLITE_FILE = '/tmp/logstash_output_jdbc_test.db'.freeze

  before(:context) do
    File.delete(JDBC_SQLITE_FILE) if File.exist? JDBC_SQLITE_FILE
  end

  include_context 'rspec setup'
  include_context 'when outputting messages'

  let(:jdbc_jar_env) do
    'JDBC_SQLITE_JAR'
  end

  let(:jdbc_settings) do
    {
      'driver_class' => 'org.sqlite.JDBC',
      'connection_string' => "jdbc:sqlite:#{JDBC_SQLITE_FILE}",
      'driver_jar_path' => ENV[jdbc_jar_env],
      'statement' => jdbc_statement,
      'max_flush_exceptions' => 1
    }
  end
end
