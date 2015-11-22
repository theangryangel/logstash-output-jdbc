require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/jdbc"
require "stud/temporary"
require "java"

describe LogStash::Outputs::Jdbc do
  def fetch_log_table_rowcount
    # sleep for a second to let the flush happen
    sleep 1
    
    stmt = @sql.createStatement()
    rs = stmt.executeQuery("select count(*) as total from log")
    count = 0
    while rs.next()
      count = rs.getInt("total")
    end
    stmt.close()

    return count
  end

  let(:base_settings) { { 
    "driver_jar_path" => @driver_jar_path,
    "connection_string" => @test_connection_string, 
    "username" => ENV['SQL_USERNAME'],
    "password" => ENV['SQL_PASSWORD'],
    "statement" => [ "insert into log (message) values(?)", "message" ],
    "max_pool_size" => 1,
    "flush_size" => 1,
    "max_flush_exceptions" => 1
  } }
  let(:test_settings) { {} }
  let(:plugin) { LogStash::Outputs::Jdbc.new(base_settings.merge(test_settings)) }
  let(:event_fields) { { "message" => "This is a message!" } }
  let(:event) { LogStash::Event.new(event_fields) }

  before(:all) do
    @driver_jar_path = File.absolute_path(ENV['SQL_JAR'])
    @test_db_path = File.join(Stud::Temporary.directory, "test.db")
    @test_connection_string = "jdbc:sqlite:#{@test_db_path}"

    require @driver_jar_path

    @sql = java.sql.DriverManager.get_connection(@test_connection_string, ENV['SQL_USERNAME'].to_s, ENV['SQL_PASSWORD'].to_s)
    stmt = @sql.createStatement()
    stmt.executeUpdate("CREATE table log (host text, timestamp datetime, message text);")
    stmt.close()
  end

  before(:each) do
    stmt = @sql.createStatement()
    stmt.executeUpdate("delete from log")
    stmt.close()
  end

  after(:all) do
   File.unlink(@test_db_path) 
   Dir.rmdir(File.dirname(@test_db_path))
  end

  describe "safe statement" do
    it "should register without errors" do
      expect { plugin.register }.to_not raise_error
    end

    it "receive event, without error" do
      plugin.register
      expect { plugin.receive(event) }.to_not raise_error

      expect(fetch_log_table_rowcount).to eq(1)
    end

  end

  describe "unsafe statement" do
    let(:event_fields) {
      { "message" => "This is a message!", "table" => "log" }
    }
    let(:test_settings) { {
      "statement" => [ "insert into %{table} (message) values(?)", "message" ],
      "unsafe_statement" => true
    } }
    
    it "should register without errors" do
      expect { plugin.register }.to_not raise_error
    end

    it "receive event, without error" do
      plugin.register
      plugin.receive(event)
      expect(fetch_log_table_rowcount).to eq(1)
    end
    
  end
end
