# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Jdbc < LogStash::Outputs::Base

  config_name "jdbc"
  milestone 1

  # Driver class
  config :driver_class, :validate => :string

  # connection string
  config :connection_string, :validate => :string, :required => true

  # [ "insert into table (message) values(?)", "%{message}" ] 
  config :statement, :validate => :array, :required => true
  
  public
  def register
    @logger.info("Starting up JDBC")
    require 'java'

    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/jdbc/*.jar")
    @logger.info(jarpath)
    Dir[jarpath].each do |jar|
      @logger.debug("JDBC loaded jar", :jar => jar)
      require jar
    end

    import @driver_class

    driver = Object.const_get(@driver_class[@driver_class.rindex('.') + 1, @driver_class.length]).new
    @connection = driver.connect(@connection_string, java.util.Properties.new)

    @logger.debug("JDBC", :connection => @connection)
  end

  def receive(event)
    return unless output?(event)
    statement = @connection.prepareStatement(@statement[0])
    @statement[1..-1].each_with_index { |i, idx| statement.setString(idx + 1, event.sprintf(i)) }
    @logger.debug("Sending SQL to server", :event => event, :sql => statement.toString())
    statement.executeUpdate()
  end

end # class LogStash::Outputs::jdbc
