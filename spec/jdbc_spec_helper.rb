require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/jdbc'
require 'stud/temporary'
require 'java'
require 'securerandom'

RSpec.configure do |c|

  def start_service(name)
    cmd = "sudo /etc/init.d/#{name}* start"

    `which systemctl`
    if $?.success?
      cmd = "sudo systemctl start #{name}"
    end

    `#{cmd}`
  end

  def stop_service(name)
    cmd = "sudo /etc/init.d/#{name}* stop"

    `which systemctl`
    if $?.success?
      cmd = "sudo systemctl stop #{name}"
    end

    `#{cmd}`
  end

end

RSpec.shared_context 'rspec setup' do
  it 'ensure jar is available' do
    expect(ENV[jdbc_jar_env]).not_to be_nil, "#{jdbc_jar_env} not defined, required to run tests"
    expect(File.exist?(ENV[jdbc_jar_env])).to eq(true), "#{jdbc_jar_env} defined, but not valid"
  end
end

RSpec.shared_context 'when initializing' do
  it 'shouldn\'t register with a missing jar file' do
    jdbc_settings['driver_jar_path'] = nil
    plugin = LogStash::Plugin.lookup('output', 'jdbc').new(jdbc_settings)
    expect { plugin.register }.to raise_error(LogStash::ConfigurationError)
  end
end

RSpec.shared_context 'when outputting messages' do
  let(:logger) { double("logger") }

  let(:jdbc_test_table) do
    'logstash_output_jdbc_test'
  end

  let(:jdbc_drop_table) do
    "DROP TABLE #{jdbc_test_table}"
  end

  let(:jdbc_create_table) do
    "CREATE table #{jdbc_test_table} (created_at datetime not null, message varchar(512) not null, message_sprintf varchar(512) not null, static_int int not null, static_bit bit not null, static_bigint bigint not null)"
  end

  let(:jdbc_statement) do
    ["insert into #{jdbc_test_table} (created_at, message, message_sprintf, static_int, static_bit, static_bigint) values(?, ?, ?, ?, ?, ?)", '@timestamp', 'message', 'sprintf-%{message}', 1, true, 4000881632477184]
  end

  let(:systemd_database_service) do
    nil
  end

  let(:event_fields) do
    { 'message' => "test-message #{SecureRandom.uuid}" }
  end

  let(:event) { LogStash::Event.new(event_fields) }

  let(:plugin) do
    # Setup plugin
    output = LogStash::Plugin.lookup('output', 'jdbc').new(jdbc_settings)
    output.register
    output.logger = logger

    # Setup table
    c = output.instance_variable_get(:@pool).getConnection

    # Derby doesn't support IF EXISTS. 
    # Seems like the quickest solution. Bleurgh.
    begin
      stmt = c.createStatement
      stmt.executeUpdate(jdbc_drop_table)
    rescue
      # noop
    ensure
      stmt.close

      stmt = c.createStatement
      stmt.executeUpdate(jdbc_create_table)
      stmt.close
      c.close
    end

    output
  end

  it 'should save a event' do
    expect { plugin.multi_receive([event]) }.to_not raise_error

    # Verify the number of items in the output table
    c = plugin.instance_variable_get(:@pool).getConnection
    stmt = c.prepareStatement("select count(*) as total from #{jdbc_test_table} where message = ?")
    stmt.setString(1, event['message'])
    rs = stmt.executeQuery
    count = 0
    count = rs.getInt('total') while rs.next
    stmt.close
    c.close

    expect(count).to eq(1)
  end

  it 'should not save event, and log an unretryable exception' do
    e = LogStash::Event.new({})

    expect(logger).to receive(:error).once.with(/JDBC - Exception. Not retrying/, Hash)
    expect { plugin.multi_receive([e]) }.to_not raise_error
  end

  it 'it should retry after a connection loss, and log a warning' do
    skip "does not run as a service" if systemd_database_service.nil?

    p = plugin

    # Check that everything is fine right now
    expect { p.multi_receive([event]) }.not_to raise_error

    stop_service(systemd_database_service)

    # Start a thread to restart the service after the fact.
    t = Thread.new(systemd_database_service) { |systemd_database_service|
      sleep 20
    
      start_service(systemd_database_service)
    }

    t.run
    
    expect(logger).to receive(:warn).at_least(:once).with(/JDBC - Exception. Retrying/, Hash)
    expect { p.multi_receive([event]) }.to_not raise_error

    # Wait for the thread to finish
    t.join
  end
end
