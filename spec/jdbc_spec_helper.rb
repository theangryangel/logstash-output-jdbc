require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/jdbc'
require 'stud/temporary'
require 'java'
require 'securerandom'

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 80000

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
  let(:logger) { 
    double("logger")
  }

  let(:jdbc_test_table) do
    'logstash_output_jdbc_test'
  end

  let(:jdbc_drop_table) do
    "DROP TABLE #{jdbc_test_table}"
  end

  let(:jdbc_statement_fields) do
    [
      {db_field: "created_at",       db_type: "datetime",      db_value: '?',  event_field: '@timestamp'},
      {db_field: "message",          db_type: "varchar(512)",  db_value: '?',  event_field: 'message'},
      {db_field: "message_sprintf",  db_type: "varchar(512)",  db_value: '?',  event_field: 'sprintf-%{message}'},
      {db_field: "static_int",       db_type: "int",           db_value: '?',  event_field: 'int'},
      {db_field: "static_bigint",    db_type: "bigint",        db_value: '?',  event_field: 'bigint'},
      {db_field: "static_float",     db_type: "float",         db_value: '?',  event_field: 'float'},
      {db_field: "static_bool",      db_type: "boolean",       db_value: '?',  event_field: 'bool'},
      {db_field: "static_bigdec",    db_type: "decimal",       db_value: '?',  event_field: 'bigdec'}
    ]
  end

  let(:jdbc_create_table) do
    fields = jdbc_statement_fields.collect { |entry| "#{entry[:db_field]} #{entry[:db_type]} not null" }.join(", ")

    "CREATE table #{jdbc_test_table} (#{fields})"
  end

  let(:jdbc_drop_table) do
    "DROP table #{jdbc_test_table}"
  end

  let(:jdbc_statement) do
    fields = jdbc_statement_fields.collect { |entry| "#{entry[:db_field]}" }.join(", ")
    values = jdbc_statement_fields.collect { |entry| "#{entry[:db_value]}" }.join(", ")
    statement = jdbc_statement_fields.collect { |entry| entry[:event_field] }

    statement.insert(0, "insert into #{jdbc_test_table} (#{fields}) values(#{values})")
  end

  let(:systemd_database_service) do
    nil
  end

  let(:event) do
    # TODO: Auto generate fields from jdbc_statement_fields
    LogStash::Event.new({ 
      message: "test-message #{SecureRandom.uuid}",
      float: 12.1,
      bigint: 4000881632477184,
      bool: true,
      int: 1,
      bigdec: BigDecimal.new("123.123")
    })
  end

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

    output
  end

  before :each do
    # Setup table
    c = plugin.instance_variable_get(:@pool).getConnection

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
  end

  # Delete table after each
  after :each do
    c = plugin.instance_variable_get(:@pool).getConnection

    stmt = c.createStatement
    stmt.executeUpdate(jdbc_drop_table)
    stmt.close
    c.close
  end

  it 'should save a event' do
    expect { plugin.multi_receive([event]) }.to_not raise_error

    # Verify the number of items in the output table
    c = plugin.instance_variable_get(:@pool).getConnection

    # TODO replace this simple count with a check of the actual contents

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
    skip "does not run as a service, or known issue with test" if systemd_database_service.nil?

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
