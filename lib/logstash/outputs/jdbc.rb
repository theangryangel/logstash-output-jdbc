# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"
require "java"

class LogStash::Outputs::Jdbc < LogStash::Outputs::Base
  # Adds buffer support
  include Stud::Buffer

  config_name "jdbc"

  # Driver class
  config :driver_class, :validate => :string

  # connection string
  config :connection_string, :validate => :string, :required => true

  # [ "insert into table (message) values(?)", "%{message}" ]
  config :statement, :validate => :array, :required => true

  # We buffer a certain number of events before flushing that out to SQL.
  # This setting controls how many events will be buffered before sending a
  # batch of events.
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
  #
  # If you change this value please ensure that you change
  # max_repeat_exceptions_time accordingly.
  config :idle_flush_time, :validate => :number, :default => 1

  # Maximum number of repeating (sequential) exceptions, before we stop retrying
  # If set to < 1, then it will infinitely retry.
  config :max_repeat_exceptions, :validate => :number, :default => 5

  # The max number of seconds since the last exception, before we consider it
  # a different cause.
  # This value should be carefully considered in respect to idle_flush_time.
  config :max_repeat_exceptions_time, :validate => :number, :default => 30

  public
  def register

    @logger.info("JDBC - Starting up")

    if ENV['LOGSTASH_HOME']
      jarpath = File.join(ENV['LOGSTASH_HOME'], "/vendor/jar/jdbc/*.jar")
    else
      jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/jdbc/*.jar")
    end

    @logger.debug("JDBC - jarpath", path: jarpath)

    jars = Dir[jarpath]
    raise Exception.new("JDBC - No jars found in jarpath. Have you read the README?") if jars.empty?

    jars.each do |jar|
      @logger.debug("JDBC - Loaded jar", :jar => jar)
      require jar
    end

    import @driver_class

    driver = Object.const_get(@driver_class[@driver_class.rindex('.') + 1, @driver_class.length]).new
    @connection = driver.connect(@connection_string, java.util.Properties.new)

    @logger.debug("JDBC - Created connection", :driver => driver, :connection => @connection)

    if (@flush_size > 1000)
      @logger.warn("JDBC - Flush size is set to > 1000. May have performance penalties, depending on your SQL engine.")
    end

    @repeat_exception_count = 0
    @last_exception_time = Time.now

    if (@max_repeat_exceptions > 0) and ((@idle_flush_time * @max_repeat_exceptions) > @max_repeat_exceptions_time)
      @logger.warn("JDBC - max_repeat_exceptions_time is set such that it may still permit a looping exception. You probably changed idle_flush_time. Considering increasing max_repeat_exceptions_time.")
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
      next if @statement.length < 2

      @statement[1..-1].each_with_index do |i, idx|
        case event[i]
        when Time, LogStash::Timestamp
          # Most reliable solution, cross JDBC driver
          statement.setString(idx + 1, event[i].iso8601())
        when Fixnum, Integer
          statement.setInt(idx + 1, event[i])
        when Float
          statement.setFloat(idx + 1, event[i])
        when String
          statement.setString(idx + 1, event[i])
        when true
          statement.setBoolean(idx + 1, true)
        when false
          statement.setBoolean(idx + 1, false)
        else
          statement.setString(idx + 1, event.sprintf(i))
        end
      end

      statement.addBatch()
    end

    begin
      @logger.debug("JDBC - Sending SQL", :sql => statement.toString())
      statement.executeBatch()
    rescue => e
      # Raising an exception will incur a retry from Stud::Buffer.
      # Since the exceutebatch failed this should mean any events failed to be
      # inserted will be re-run. We're going to log it for the lols anyway.
      @logger.warn("JDBC - Exception. Will automatically retry", :exception => e)
      if e.getNextException() != nil
	      @logger.warn("JDBC - Exception. Will automatically retry", :exception => e.getNextException())
  	  end
    end

    statement.close()
  end

  def on_flush_error(e)
    return if @max_repeat_exceptions < 1

    if @last_exception == e.to_s
      @repeat_exception_count += 1
    else
      @repeat_exception_count = 0
    end

    if (@repeat_exception_count >= @max_repeat_exceptions) and (Time.now - @last_exception_time) < @max_repeat_exceptions_time
      @logger.error("JDBC - Exception repeated more than the maximum configured", :exception => e, :max_repeat_exceptions => @max_repeat_exceptions, :max_repeat_exceptions_time => @max_repeat_exceptions_time)
      raise e
    end

    @last_exception_time = Time.now
    @last_exception = e.to_s
  end

  def teardown
    buffer_flush(:final => true)
    @connection.close()
    super
  end

end # class LogStash::Outputs::jdbc
