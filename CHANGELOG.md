# Change Log
All notable changes to this project will be documented in this file, from 0.2.0.

## [1.0.0-pre] - UNRELEASED
  - Test coverage extended to multiple SQL engines
  - Change: Timestamps are sent to SQL without timezone (See https://github.com/theangryangel/logstash-output-jdbc/issues/33 for justification)
  - Change: Removes jar files from repository, in favour of vendoring using jar-dependencies
  - Change: Updates to logstash-api v2.0 
  - Change: Switches from slf4j-nop to log4j for HikariCP logging
  - Change: Adds improved support to deal with partially failed batches of inserts

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
