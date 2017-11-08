# Change Log
All notable changes to this project will be documented in this file, from 0.2.0.

## [5.3.0] - 2017-11-08
  - Adds configuration options `enable_event_as_json_keyword` and `event_as_json_keyword`
  - Adds BigDecimal support
  - Adds additional logging for debugging purposes (with thanks to @mlkmhd's work)

## [5.2.1] - 2017-04-09
  - Adds Array and Hash to_json support for non-sprintf syntax

## [5.2.0] - 2017-04-01
  - Upgrades HikariCP to latest
  - Fixes HikariCP logging integration issues

## [5.1.0] - 2016-12-17
  - phoenix-thin fixes for issue #60

## [5.0.0] - 2016-11-03
  - logstash v5 support

## [0.3.1] - 2016-08-28
  - Adds connection_test configuration option, to prevent the connection test from occuring, allowing the error to be suppressed.
    Useful for cockroachdb deployments. https://github.com/theangryangel/logstash-output-jdbc/issues/53 

## [0.3.0] - 2016-07-24
  - Brings tests from v5 branch, providing greater coverage
  - Removes bulk update support, due to inconsistent behaviour
  - Plugin now marked as threadsafe, meaning only 1 instance per-Logstash
    - Raises default max_pool_size to match the default number of workers (1 connection per worker)

## [0.2.10] - 2016-07-07
  - Support non-string entries in statement array
  - Adds backtrace to exception logging

## [0.2.9] - 2016-06-29
  - Fix NameError exception. 
  - Moved log_jdbc_exception calls

## [0.2.7] - 2016-05-29
  - Backport retry exception logic from v5 branch
  - Backport improved timestamp compatibility from v5 branch

## [0.2.6] - 2016-05-02
  - Fix for exception infinite loop

## [0.2.5] - 2016-04-11
### Added
  - Basic tests running against DerbyDB
  - Fix for converting Logstash::Timestamp to iso8601 from @hordijk

## [0.2.4] - 2016-04-07
  - Documentation fixes from @hordijk

## [0.2.3] - 2016-02-16
  - Bug fixes

## [0.2.2] - 2015-12-30
  - Bug fixes

## [0.2.1] -  2015-12-22
  - Support for connection pooling support added through HikariCP
  - Support for unsafe statement handling (allowing dynamic queries)
  - Altered exception handling to now count sequential flushes with exceptions thrown
