require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/jdbc"
require "stud/temporary"
require "java"
require 'securerandom'

RSpec.shared_context 'rspec setup' do

  it 'ensure jar is available' do
    expect(ENV[jdbc_jar_env]).not_to be_nil, "#{jdbc_jar_env} not defined, required to run tests"
    expect(File.exists?(ENV[jdbc_jar_env])).to eq(true), "#{jdbc_jar_env} defined, but not valid"
  end

end

RSpec.shared_context 'when initializing' do

  it 'shouldn\'t register with a missing jar file' do
    jdbc_settings['driver_jar_path'] = nil
    plugin = LogStash::Plugin.lookup("output", "jdbc").new(jdbc_settings)
    expect { plugin.register }.to raise_error
  end

end

RSpec.shared_context 'when outputting messages' do

  let (:jdbc_test_table) do
    'logstash_output_jdbc_test'
  end

  let(:jdbc_drop_table) do
    "DROP TABLE IF EXISTS #{jdbc_test_table}"
  end

  let(:jdbc_create_table) do
    "CREATE table #{jdbc_test_table} (created_at datetime, message varchar(512))"
  end

  let(:event_fields) do
    { message: "test-message #{SecureRandom.uuid}" }
  end

  let(:event) { LogStash::Event.new(event_fields) }

  let(:plugin) {
    # Setup plugin
    output = LogStash::Plugin.lookup("output", "jdbc").new(jdbc_settings)
    output.register
    if ENV['JDBC_DEBUG'] == '1'
      output.logger.subscribe(STDOUT)
    end

    # Setup table
    c = output.instance_variable_get(:@pool).getConnection()

    unless jdbc_drop_table.nil?
      stmt = c.createStatement()
      stmt.executeUpdate(jdbc_drop_table)
      stmt.close()
    end

    stmt = c.createStatement()
    stmt.executeUpdate(jdbc_create_table)
    stmt.close()
    c.close()

    output
  }

  it 'should save a event' do

    previous_exceptions_count = plugin.instance_variable_get(:@exceptions_tracker).not_nil_length

    expect { plugin.receive(event) }.to_not raise_error

    # Force flush the buffer, so that we know anything in the buffer
    # has been sent
    plugin.buffer_flush(force: true)

    expect(plugin.instance_variable_get(:@exceptions_tracker).not_nil_length).to eq(previous_exceptions_count)

    # Verify the number of items in the output table
    c = plugin.instance_variable_get(:@pool).getConnection()
    stmt = c.prepareStatement("select count(*) as total from #{jdbc_test_table} where message = ?")
    stmt.setString(1, event.get('message'))
    rs = stmt.executeQuery()
    count = 0
    while rs.next()
      count = rs.getInt("total")
    end
    stmt.close()
    c.close()

    expect(count).to eq(1)
  end

end
