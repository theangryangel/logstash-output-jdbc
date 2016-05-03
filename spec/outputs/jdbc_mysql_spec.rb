require_relative "../jdbc_spec_helper"

describe "logstash-output-jdbc: mysql", if: ENV['JDBC_MYSQL_JAR'] do

  include_context "rspec setup"
  include_context "when initializing"
  include_context "when outputting messages"

  let(:jdbc_jar_env) do
    'JDBC_MYSQL_JAR'
  end

  let(:jdbc_settings) do
    { 
      "driver_class" => "com.mysql.jdbc.Driver",
      "connection_string" => "jdbc:mysql://localhost/logstash_output_jdbc_test?user=root",
      "driver_jar_path" => ENV[jdbc_jar_env],
      "statement" => [ "insert into #{jdbc_test_table} (created_at, message) values(?, ?)", "@timestamp", "message" ]
    }
  end

end
