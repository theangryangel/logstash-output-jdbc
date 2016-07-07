# Change Log
All notable changes to this project will be documented in this file, from 0.2.0.

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
