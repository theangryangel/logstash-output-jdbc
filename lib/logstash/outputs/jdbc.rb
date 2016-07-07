# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"
require "java"
require "logstash-output-jdbc_jars"
require "logstash-output-jdbc_ring-buffer"

# Write events to a SQL engine, using JDBC.
#
# It is upto the user of the plugin to correctly configure the plugin. This
# includes correctly crafting the SQL statement, and matching the number of
# parameters correctly.
class LogStash::Outputs::Jdbc < LogStash::Outputs::Base
  # Adds buffer support
  include Stud::Buffer

  STRFTIME_FMT = '%Y-%m-%d %T.%L'.freeze

  RETRYABLE_SQLSTATE_CLASSES = [
    # Classes of retryable SQLSTATE codes
    # Not all in the class will be retryable. However, this is the best that 
    # we've got right now.
    # If a custom state code is required, set it in retry_sql_states.
    '08', # Connection Exception
    '24', # Invalid Cursor State (Maybe retry-able in some circumstances)
    '25', # Invalid Transaction State 
    '40', # Transaction Rollback 
    '53', # Insufficient Resources
    '54', # Program Limit Exceeded (MAYBE)
    '55', # Object Not In Prerequisite State
    '57', # Operator Intervention
    '58', # System Error
  ].freeze

  config_name "jdbc"

  # Driver class - Reintroduced for https://github.com/theangryangel/logstash-output-jdbc/issues/26
  config :driver_class, :validate => :string

  # Does the JDBC driver support autocommit?
  config :driver_auto_commit, :validate => :boolean, :default => true, :required => true

  # Where to find the jar
  # Defaults to not required, and to the original behaviour
  config :driver_jar_path, :validate => :string, :required => false

  # jdbc connection string
  config :connection_string, :validate => :string, :required => true

  # jdbc username - optional, maybe in the connection string
  config :username, :validate => :string, :required => false

  # jdbc password - optional, maybe in the connection string
  config :password, :validate => :string, :required => false

  # [ "insert into table (message) values(?)", "%{message}" ]
  config :statement, :validate => :array, :required => true

  # If this is an unsafe statement, use event.sprintf
  # This also has potential performance penalties due to having to create a 
  # new statement for each event, rather than adding to the batch and issuing
  # multiple inserts in 1 go
  config :unsafe_statement, :validate => :boolean, :default => false

  # Number of connections in the pool to maintain
  config :max_pool_size, :validate => :number, :default => 5

  # Connection timeout
  config :connection_timeout, :validate => :number, :default => 10000

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
  # max_flush_exceptions accordingly.
  config :idle_flush_time, :validate => :number, :default => 1

  # Maximum number of sequential flushes which encounter exceptions, before we stop retrying.
  # If set to < 1, then it will infinitely retry.
  # 
  # You should carefully tune this in relation to idle_flush_time if your SQL server
  # is not highly available.
  # i.e. If your idle_flush_time is 1, and your max_flush_exceptions is 200, and your SQL server takes
  # longer than 200 seconds to reboot, then logstash will stop.
  config :max_flush_exceptions, :validate => :number, :default => 0

  config :max_repeat_exceptions, :obsolete => "This has been replaced by max_flush_exceptions - which behaves slightly differently. Please check the documentation."
  config :max_repeat_exceptions_time, :obsolete => "This is no longer required"

  public
  def register
    @logger.info("JDBC - Starting up")

    load_jar_files!

    @exceptions_tracker = RingBuffer.new(@max_flush_exceptions)

    if (@flush_size > 1000)
      @logger.warn("JDBC - Flush size is set to > 1000")
    end

    if @statement.length < 1
      @logger.error("JDBC - No statement provided. Configuration error.")
    end

    if (!@unsafe_statement and @statement.length < 2) 
      @logger.error("JDBC - Statement has no parameters. No events will be inserted into SQL as you're not passing any event data. Likely configuration error.")
    end

    setup_and_test_pool!

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end

  def receive(event)
    return unless output?(event) or event.cancelled?
    return unless @statement.length > 0

    buffer_receive(event)
  end

  def flush(events, teardown=false)
    if @unsafe_statement == true
      unsafe_flush(events, teardown)
    else
      safe_flush(events, teardown)
    end
  end

  def on_flush_error(e)
    return if @max_flush_exceptions < 1

    @exceptions_tracker << e.class

    if @exceptions_tracker.reject { |i| i.nil? }.count >= @max_flush_exceptions
      @logger.error("JDBC - max_flush_exceptions has been reached")
      raise LogStash::ShutdownSignal.new
    end
  end

  def teardown
    buffer_flush(:final => true)
    @pool.close()
    super
  end

  private

  def setup_and_test_pool!  
    # Setup pool
    @pool = Java::ComZaxxerHikari::HikariDataSource.new

    @pool.setAutoCommit(@driver_auto_commit)
    @pool.setDriverClassName(@driver_class) if @driver_class

    @pool.setJdbcUrl(@connection_string)

    @pool.setUsername(@username) if @username
    @pool.setPassword(@password) if @password

    @pool.setMaximumPoolSize(@max_pool_size)
    @pool.setConnectionTimeout(@connection_timeout)

    validate_connection_timeout = (@connection_timeout / 1000) / 2

    # Test connection
    test_connection = @pool.getConnection()
    unless test_connection.isValid(validate_connection_timeout)
      @logger.error("JDBC - Connection is not valid. Please check connection string or that your JDBC endpoint is available.")
    end
    test_connection.close()
  end

  def load_jar_files!
    # Load jar from driver path
    unless @driver_jar_path.nil?
      raise Exception.new("JDBC - Could not find jar file at given path. Check config.") unless File.exists? @driver_jar_path
      require @driver_jar_path
      return
    end

    # Revert original behaviour of loading from vendor directory
    # if no path given
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
  end

  def safe_flush(events, teardown=false)
    connection = nil
    statement = nil
    
    begin
      connection = @pool.getConnection()
    rescue => e
      log_jdbc_exception(e, true)
      raise
    end

    begin
      statement = connection.prepareStatement(@statement[0])

      events.each do |event|
        next if event.cancelled?
        next if @statement.length < 2
        statement = add_statement_event_params(statement, event)

        statement.addBatch()
      end

      statement.executeBatch()
      statement.close()
      @exceptions_tracker << nil
    rescue => e
      if retry_exception?(e)
        raise
      end
    ensure
      statement.close() unless statement.nil?
      connection.close() unless connection.nil?
    end
  end

  def unsafe_flush(events, teardown=false)
    connection = nil
    statement = nil
    begin
      connection = @pool.getConnection()
    rescue => e
      log_jdbc_exception(e, true)
      raise
    end

    begin
      events.each do |event|
        next if event.cancelled?

        statement = connection.prepareStatement(event.sprintf(@statement[0]))
        statement = add_statement_event_params(statement, event) if @statement.length > 1

        statement.execute()

        # cancel the event, since we may end up outputting the same event multiple times
        # if an exception happens later down the line
        event.cancel
        @exceptions_tracker << nil
      end
    rescue => e
      if retry_exception?(e)
        raise
      end
    ensure
      statement.close() unless statement.nil?
      connection.close() unless connection.nil?
    end
  end

  def add_statement_event_params(statement, event)
    @statement[1..-1].each_with_index do |i, idx|
      if i.is_a? String 
        value = event[i]
        if value.nil? and i =~ /%\{/
          value = event.sprintf(i)
        end
      else
        value = i
      end
      
      case value
      when Time
        # See LogStash::Timestamp, below, for the why behind strftime.
        statement.setString(idx + 1, value.strftime(STRFTIME_FMT))
      when LogStash::Timestamp
        # XXX: Using setString as opposed to setTimestamp, because setTimestamp
        # doesn't behave correctly in some drivers (Known: sqlite)
        #
        # Additionally this does not use `to_iso8601`, since some SQL databases
        # choke on the 'T' in the string (Known: Derby).
        #
        # strftime appears to be the most reliable across drivers.
        statement.setString(idx + 1, value.time.strftime(STRFTIME_FMT))
      when Fixnum, Integer
        statement.setInt(idx + 1, value)
      when Float
        statement.setFloat(idx + 1, value)
      when String
        statement.setString(idx + 1, value)
      when true, false
        statement.setBoolean(idx + 1, value)
      else
        statement.setString(idx + 1, nil)
      end
    end

    statement
  end


  def log_jdbc_exception(exception, retrying)
    current_exception = exception
    log_text = 'JDBC - Exception. ' + (retrying ? 'Retrying' : 'Not retrying') + '.'
    log_method = (retrying ? 'warn' : 'error')

    loop do
      @logger.send(log_method, log_text, :exception => current_exception, :backtrace => current_exception.backtrace)

      if current_exception.respond_to? 'getNextException'
        current_exception = current_exception.getNextException()
      else
        current_exception = nil
      end

      break if current_exception == nil
    end
  end

  def retry_exception?(exception)
    retrying = (exception.respond_to? 'getSQLState' and RETRYABLE_SQLSTATE_CLASSES.include?(exception.getSQLState.to_s[0,2]))
    log_jdbc_exception(exception, retrying)

    retrying
  end
end # class LogStash::Outputs::jdbc
