# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'concurrent'
require 'stud/interval'
require 'java'
require 'logstash-output-jdbc_jars'
require 'json'
require 'bigdecimal'

# Write events to a SQL engine, using JDBC.
#
# It is upto the user of the plugin to correctly configure the plugin. This
# includes correctly crafting the SQL statement, and matching the number of
# parameters correctly.
class LogStash::Outputs::Jdbc < LogStash::Outputs::Base
  concurrency :shared

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

  config_name 'jdbc'

  # Driver class - Reintroduced for https://github.com/theangryangel/logstash-output-jdbc/issues/26
  config :driver_class, validate: :string

  # Does the JDBC driver support autocommit?
  config :driver_auto_commit, validate: :boolean, default: true, required: true

  # Where to find the jar
  # Defaults to not required, and to the original behaviour
  config :driver_jar_path, validate: :string, required: false

  # jdbc connection string
  config :connection_string, validate: :string, required: true

  # jdbc username - optional, maybe in the connection string
  config :username, validate: :string, required: false

  # jdbc password - optional, maybe in the connection string
  config :password, validate: :string, required: false

  # [ "insert into table (message) values(?)", "%{message}" ]
  config :statement, validate: :array, required: true

  # If this is an unsafe statement, use event.sprintf
  # This also has potential performance penalties due to having to create a
  # new statement for each event, rather than adding to the batch and issuing
  # multiple inserts in 1 go
  config :unsafe_statement, validate: :boolean, default: false

  # Number of connections in the pool to maintain
  config :max_pool_size, validate: :number, default: 5

  # Connection timeout
  config :connection_timeout, validate: :number, default: 10000

  # We buffer a certain number of events before flushing that out to SQL.
  # This setting controls how many events will be buffered before sending a
  # batch of events.
  config :flush_size, validate: :number, default: 1000

  # Set initial interval in seconds between retries. Doubled on each retry up to `retry_max_interval`
  config :retry_initial_interval, validate: :number, default: 2

  # Maximum time between retries, in seconds
  config :retry_max_interval, validate: :number, default: 128

  # Any additional custom, retryable SQL state codes. 
  # Suitable for configuring retryable custom JDBC SQL state codes.
  config :retry_sql_states, validate: :array, default: []

  # Run a connection test on start.
  config :connection_test, validate: :boolean, default: true

  # Connection test and init string, required for some JDBC endpoints
  # notable phoenix-thin - see logstash-output-jdbc issue #60
  config :connection_test_query, validate: :string, required: false

  # Maximum number of sequential failed attempts, before we stop retrying.
  # If set to < 1, then it will infinitely retry.
  # At the default values this is a little over 10 minutes
  config :max_flush_exceptions, validate: :number, default: 10

  config :max_repeat_exceptions, obsolete: 'This has been replaced by max_flush_exceptions - which behaves slightly differently. Please check the documentation.'
  config :max_repeat_exceptions_time, obsolete: 'This is no longer required'
  config :idle_flush_time, obsolete: 'No longer necessary under Logstash v5'
  
  # Allows the whole event to be converted to JSON
  config :enable_event_as_json_keyword, validate: :boolean, default: false
  
  # The magic key used to convert the whole event to JSON. If you need this, and you have the default in your events, you can use this to change your magic keyword.
  config :event_as_json_keyword, validate: :string, default: '@event'

  def register
    @logger.info('JDBC - Starting up')

    load_jar_files!

    @stopping = Concurrent::AtomicBoolean.new(false)

    @logger.warn('JDBC - Flush size is set to > 1000') if @flush_size > 1000

    if @statement.empty?
      @logger.error('JDBC - No statement provided. Configuration error.')
    end

    if !@unsafe_statement && @statement.length < 2
      @logger.error("JDBC - Statement has no parameters. No events will be inserted into SQL as you're not passing any event data. Likely configuration error.")
    end

    setup_and_test_pool!
  end

  def multi_receive(events)
    events.each_slice(@flush_size) do |slice|
      retrying_submit(slice)
    end
  end

  def close
    @stopping.make_true
    @pool.close
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

    if !@connection_test_query.nil? and @connection_test_query.length > 1
      @pool.setConnectionTestQuery(@connection_test_query)
      @pool.setConnectionInitSql(@connection_test_query)
    end

    return unless @connection_test

    # Test connection
    test_connection = @pool.getConnection
    unless test_connection.isValid(validate_connection_timeout)
      @logger.warn('JDBC - Connection is not reporting as validate. Either connection is invalid, or driver is not getting the appropriate response.')
    end
    test_connection.close
  end

  def load_jar_files!
    # Load jar from driver path
    unless @driver_jar_path.nil?
      raise LogStash::ConfigurationError, 'JDBC - Could not find jar file at given path. Check config.' unless File.exist? @driver_jar_path
      require @driver_jar_path
      return
    end

    # Revert original behaviour of loading from vendor directory
    # if no path given
    jarpath = if ENV['LOGSTASH_HOME']
                File.join(ENV['LOGSTASH_HOME'], '/vendor/jar/jdbc/*.jar')
              else
                File.join(File.dirname(__FILE__), '../../../vendor/jar/jdbc/*.jar')
              end

    @logger.trace('JDBC - jarpath', path: jarpath)

    jars = Dir[jarpath]
    raise LogStash::ConfigurationError, 'JDBC - No jars found. Have you read the README?' if jars.empty?

    jars.each do |jar|
      @logger.trace('JDBC - Loaded jar', jar: jar)
      require jar
    end
  end

  def submit(events)
    connection = nil
    statement = nil
    events_to_retry = []

    begin
      connection = @pool.getConnection
    rescue => e
      log_jdbc_exception(e, true, nil)
      # If a connection is not available, then the server has gone away
      # We're not counting that towards our retry count.
      return events, false
    end

    events.each do |event|
      begin
        statement = connection.prepareStatement(
          (@unsafe_statement == true) ? event.sprintf(@statement[0]) : @statement[0]
        )
        statement = add_statement_event_params(statement, event) if @statement.length > 1
        statement.execute
      rescue => e
        if retry_exception?(e, event.to_json())
          events_to_retry.push(event)
        end
      ensure
        statement.close unless statement.nil?
      end
    end

    connection.close unless connection.nil?

    return events_to_retry, true
  end

  def retrying_submit(actions)
    # Initially we submit the full list of actions
    submit_actions = actions
    count_as_attempt = true

    attempts = 1

    sleep_interval = @retry_initial_interval
    while @stopping.false? and (submit_actions and !submit_actions.empty?)
      return if !submit_actions || submit_actions.empty? # If everything's a success we move along
      # We retry whatever didn't succeed
      submit_actions, count_as_attempt = submit(submit_actions)

      # Everything was a success!
      break if !submit_actions || submit_actions.empty?

      if @max_flush_exceptions > 0 and count_as_attempt == true
        attempts += 1

        if attempts > @max_flush_exceptions
          @logger.error("JDBC - max_flush_exceptions has been reached. #{submit_actions.length} events have been unable to be sent to SQL and are being dropped. See previously logged exceptions for details.")
          break
        end
      end

      # If we're retrying the action sleep for the recommended interval
      # Double the interval for the next time through to achieve exponential backoff
      Stud.stoppable_sleep(sleep_interval) { @stopping.true? }
      sleep_interval = next_sleep_interval(sleep_interval)
    end
  end

  def add_statement_event_params(statement, event)
    @statement[1..-1].each_with_index do |i, idx|
      if @enable_event_as_json_keyword == true and i.is_a? String and i == @event_as_json_keyword
        value = event.to_json
      elsif i.is_a? String
        value = event.get(i)
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
        if value > 2147483647 or value < -2147483648
          statement.setLong(idx + 1, value)
        else
          statement.setInt(idx + 1, value)
        end
      when BigDecimal
        statement.setBigDecimal(idx + 1, value.to_java)
      when Float
        statement.setFloat(idx + 1, value)
      when String
        statement.setString(idx + 1, value)
      when Array, Hash
        statement.setString(idx + 1, value.to_json)
      when true, false
        statement.setBoolean(idx + 1, value)
      else
        statement.setString(idx + 1, nil)
      end
    end

    statement
  end

  def retry_exception?(exception, event)
    retrying = (exception.respond_to? 'getSQLState' and (RETRYABLE_SQLSTATE_CLASSES.include?(exception.getSQLState.to_s[0,2]) or @retry_sql_states.include?(exception.getSQLState)))
    log_jdbc_exception(exception, retrying, event)

    retrying
  end

  def log_jdbc_exception(exception, retrying, event)
    current_exception = exception
    log_text = 'JDBC - Exception. ' + (retrying ? 'Retrying' : 'Not retrying') 
    
    log_method = (retrying ? 'warn' : 'error')

    loop do
      # TODO reformat event output so that it only shows the fields necessary.

      @logger.send(log_method, log_text, :exception => current_exception, :statement => @statement[0], :event => event)

      if current_exception.respond_to? 'getNextException'
        current_exception = current_exception.getNextException()
      else
        current_exception = nil
      end

      break if current_exception == nil
    end
  end

  def next_sleep_interval(current_interval)
    doubled = current_interval * 2
    doubled > @retry_max_interval ? @retry_max_interval : doubled
  end
end # class LogStash::Outputs::jdbc
