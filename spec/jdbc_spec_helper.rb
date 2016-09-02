require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/jdbc'
require 'stud/temporary'
require 'java'
require 'securerandom'

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
  let(:logger) { 
    double("logger")
  }

  let(:jdbc_test_table) do
    'logstash_output_jdbc_test'
  end

  let(:jdbc_drop_table) do
    "DROP TABLE #{jdbc_test_table}"
  end

  let(:jdbc_create_table) do
    "CREATE table #{jdbc_test_table} (created_at datetime not null, message varchar(512) not null, message_sprintf varchar(512) not null, static_int int not null, static_bit bit not null)"
  end

  let(:jdbc_statement) do
    ["insert into #{jdbc_test_table} (created_at, message, message_sprintf, static_int, static_bit) values(?, ?, ?, ?, ?)", '@timestamp', 'message', 'sprintf-%{message}', 1, true]
  end

  let(:systemd_database_service) do
    nil
  end

  let(:event_fields) do
    { message: "test-message #{SecureRandom.uuid}" }
  end

  let(:event) { LogStash::Event.new(event_fields) }

  let(:plugin) do
    # Setup logger
    allow(LogStash::Outputs::Jdbc).to receive(:logger).and_return(logger)
    
    # XXX: Suppress reflection logging. There has to be a better way around this.
    allow(logger).to receive(:debug).with(/config LogStash::/)

    # Suppress beta warnings.
    allow(logger).to receive(:info).with(/Please let us know if you find bugs or have suggestions on how to improve this plugin./)

    # Suppress start up messages.
    expect(logger).to receive(:info).once.with(/JDBC - Starting up/)

    # Setup plugin
    output = LogStash::Plugin.lookup('output', 'jdbc').new(jdbc_settings)
    output.register

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
    stmt.setString(1, event.get('message'))
    rs = stmt.executeQuery
    count = 0
    count = rs.getInt('total') while rs.next
    stmt.close
    c.close

    expect(count).to eq(1)
  end

  it 'should not save event, and log an unretryable exception' do
    e = event
    original_event = e.get('message')
    e.set('message', nil)

    expect(logger).to receive(:error).once.with(/JDBC - Exception. Not retrying/, Hash)
    expect { plugin.multi_receive([event]) }.to_not raise_error

    e.set('message', original_event)
  end

  it 'it should retry after a connection loss, and log a warning' do
    skip "does not run as a service" if systemd_database_service.nil?

    p = plugin

    # Check that everything is fine right now
    expect { p.multi_receive([event]) }.not_to raise_error

    # Start a thread to stop and restart the service.
    t = Thread.new(systemd_database_service) { |systemd_database_service|
      start_stop_cmd = 'sudo /etc/init.d/%<service>s* %<action>s'

      `which systemctl`
      if $?.success?
        start_stop_cmd = 'sudo systemctl %<action>s %<service>s'
      end

      cmd = start_stop_cmd % { action: 'stop', service: systemd_database_service }
      `#{cmd}`
      sleep 10

      cmd = start_stop_cmd % { action: 'start', service: systemd_database_service }
      `#{cmd}`
    }

    # Wait a few seconds to the service to stop
    sleep 5

    expect(logger).to receive(:warn).at_least(:once).with(/JDBC - Exception. Retrying/, Hash)
    expect { p.multi_receive([event]) }.to_not raise_error

    t.join
  end
end
