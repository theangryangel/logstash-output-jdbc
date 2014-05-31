# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"

class LogStash::Outputs::Jdbc < LogStash::Outputs::Base
  # Adds buffer support
  include Stud::Buffer

  config_name "jdbc"
  milestone 1

  # Driver class
  config :driver_class, :validate => :string

  # connection string
  config :connection_string, :validate => :string, :required => true

  # [ "insert into table (message) values(?)", "%{message}" ] 
  config :statement, :validate => :array, :required => true

  # This plugin uses the bulk index api for improved performance.
  # To make efficient bulk insert calls, we will buffer a certain number of
  # events before flushing that out to SQL. This setting
  # controls how many events will be buffered before sending a batch
  # of events.
  config :flush_size, :validate => :number, :default => 1000

  # The amount of time since last flush before a flush is forced.
  #
  # This setting helps ensure slow event rates don't get stuck in Logstash.
  # For example, if your `flush_size` is 100, and you have received 10 events,
  # and it has been more than `idle_flush_time` seconds since the last flush,
  # Logstash will flush those 10 events automatically.
  #
  # This helps keep both fast and slow log streams moving along in
  # a timely manner.
  config :idle_flush_time, :validate => :number, :default => 1
  
  public
  def register
    @logger.info("Starting up JDBC")
    require "java"

    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/jdbc/*.jar")
    @logger.info(jarpath)
    Dir[jarpath].each do |jar|
      @logger.debug("JDBC loaded jar", :jar => jar)
      require jar
    end

    import @driver_class

    driver = Object.const_get(@driver_class[@driver_class.rindex('.') + 1, @driver_class.length]).new
    @connection = driver.connect(@connection_string, java.util.Properties.new)

    @logger.debug("JDBC", :driver => driver, :connection => @connection)

    if (@flush_size > 1000)
      @logger.warn("JDBC - flush size is set to > 1000. May have performance penalties, depending on your SQL engine.")
    end

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end

  def receive(event)
    return unless output?(event)
    return unless @statement.length > 0

    buffer_receive(event)
  end

  def flush(events, teardown=false)
    statement = @connection.prepareStatement(@statement[0])
    
    events.each do |event|
      @statement[1..-1].each_with_index { |i, idx| statement.setString(idx + 1, event.sprintf(i)) } if @statement.length > 1
      statement.addBatch()
    end

    begin
      @logger.debug("Sending SQL to server", :event => event, :sql => statement.toString())      
      statement.executeBatch()
    rescue Exception => e
      @logger.error("JDBC Exception", :exception => e)

      # Raising an exception will incur a retry from Stud::Buffer.
      # Since the exceutebatch failed this should mean any events failed to be
      # inserted will be re-run.
      # We're only capturing the exception so we can pass it to the logger, log
      # it and then re-raise it.
      raise Exception.new("JDBC - Flush failed - #{e.message}")
    end

    statement.close()
  end

  def teardown
    buffer_flush(:final => true)
    @connection.close()
    super
  end

end # class LogStash::Outputs::jdbc
