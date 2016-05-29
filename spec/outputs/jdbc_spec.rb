require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/jdbc"
require "stud/temporary"
require "java"

describe LogStash::Outputs::Jdbc do

  let(:derby_settings) do
    { 
      "driver_class" => "org.apache.derby.jdbc.EmbeddedDriver",
      "connection_string" => "jdbc:derby:memory:testdb;create=true",
      "driver_jar_path" => ENV['JDBC_DERBY_JAR'],
      "statement" => [ "insert into log (created_at, message) values(?, ?)", "@timestamp" "message" ]
    }
  end

  context 'rspec setup' do

    it 'ensure derby is available' do
      j = ENV['JDBC_DERBY_JAR']
      expect(j).not_to be_nil, "JDBC_DERBY_JAR not defined, required to run tests"
      expect(File.exists?(j)).to eq(true), "JDBC_DERBY_JAR defined, but not valid"
    end
    
  end

  context 'when initializing' do

    it 'shouldn\'t register without a config' do
      expect { 
        LogStash::Plugin.lookup("output", "jdbc").new()
      }.to raise_error(LogStash::ConfigurationError)
    end

    it 'shouldn\'t register with a missing jar file' do
      derby_settings['driver_jar_path'] = nil
      plugin = LogStash::Plugin.lookup("output", "jdbc").new(derby_settings)
      expect { plugin.register }.to raise_error
    end

    it 'shouldn\'t register with a missing jar file' do
      derby_settings['connection_string'] = nil
      plugin = LogStash::Plugin.lookup("output", "jdbc").new(derby_settings)
      expect { plugin.register }.to raise_error
    end

  end

  context 'when outputting messages' do

    let(:event_fields) do
      { message: 'test-message' }
    end
    let(:event) { LogStash::Event.new(event_fields) }
    let(:plugin) {
      # Setup plugin
      output = LogStash::Plugin.lookup("output", "jdbc").new(derby_settings)
      output.register
      if ENV['JDBC_DEBUG'] == '1'
        output.logger.subscribe(STDOUT)
      end

      # Setup table
      c = output.instance_variable_get(:@pool).getConnection()
      stmt = c.createStatement()
      stmt.executeUpdate("CREATE table log (created_at timestamp, message varchar(512))")
      stmt.close()
      c.close()

      output
    }

    it 'should save a event' do
      expect { plugin.receive(event) }.to_not raise_error
      
      # Wait for 1 second, for the buffer to flush
      sleep 1

      c = plugin.instance_variable_get(:@pool).getConnection()
      stmt = c.createStatement()
      rs = stmt.executeQuery("select count(*) as total from log")
      count = 0
      while rs.next()
        count = rs.getInt("total")
      end
      stmt.close()
      c.close()

      expect(count).to be > 0
    end

  end

end
