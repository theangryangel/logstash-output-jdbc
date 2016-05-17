# logstash-output-jdbc 

[![Build Status](https://travis-ci.org/theangryangel/logstash-output-jdbc.svg?branch=master)](https://travis-ci.org/theangryangel/logstash-output-jdbc)

This plugin is provided as an external plugin and is not part of the Logstash project.

This plugin allows you to output to SQL databases, using JDBC adapters.
See below for tested adapters, and example configurations.

This has not yet been extensively tested with all JDBC drivers and may not yet work for you.

If you do find this works for a JDBC driver without an example, let me know and provide a small example configuration if you can.

This plugin does not bundle any JDBC jar files, and does expect them to be in a
particular location. Please ensure you read the 4 installation lines below.

## Changelog
See CHANGELOG.md

## Versions
Released versions are available via rubygems, and typically tagged.

For development:
  - See master branch for logstash v5 (currently **development only**)
  - See v2.x branch for logstash v2
  - See v1.5 branch for logstash v1.5 
  - See v1.4 branch for logstash 1.4

## Installation
  - Run `bin/logstash-plugin install logstash-output-jdbc` in your logstash installation directory
  - Now either:
    - Use driver_jar_path in your configuraton to specify a path to your jar file
  - Or:
    - Create the directory vendor/jar/jdbc in your logstash installation (`mkdir -p vendor/jar/jdbc/`)
    - Add JDBC jar files to vendor/jar/jdbc in your logstash installation
  - And then configure (examples can be found in the examples directory)

## Configuration options

| Option | Type | Description | Required? | Default |
| ------ | ---- | ----------- | --------- | ------- |
| driver_class | String | Specify a driver class if autoloading fails | No | |
| driver_auto_commit | Boolean | If the driver does not support auto commit, you should set this to false | No | True |
| driver_jar_path | String | File path to jar file containing your JDBC driver. This is optional, and all JDBC jars may be placed in $LOGSTASH_HOME/vendor/jar/jdbc instead. | No | |
| connection_string | String | JDBC connection URL | Yes | |
| username | String | JDBC username - this is optional as it may be included in the connection string, for many drivers | No | |
| password | String | JDBC password - this is optional as it may be included in the connection string, for many drivers | No | |
| statement | Array | An array of strings representing the SQL statement to run. Index 0 is the SQL statement that is prepared, all other array entries are passed in as parameters (in order). A parameter may either be a property of the event (i.e. "@timestamp", or "host") or a formatted string (i.e. "%{host} - %{message}" or "%{message}"). If a key is passed then it will be automatically converted as required for insertion into SQL. If it's a formatted string then it will be passed in verbatim. | Yes |  |
| unsafe_statement | Boolean | If yes, the statement is evaluated for event fields - this allows you to use dynamic table names, etc. **This is highly dangerous** and you should **not** use this unless you are 100% sure that the field(s) you are passing in are 100% safe. Failure to do so will result in possible SQL injections. Please be aware that there is also a potential performance penalty as each event must be evaluated and inserted into SQL one at a time, where as when this is false multiple events are inserted at once. Example statement: [ "insert into %{table_name_field} (column) values(?)", "fieldname" ] | No | False |
| max_pool_size | Number | Maximum number of connections to open to the SQL server at any 1 time | No | 5 |
| connection_timeout | Number | Number of seconds before a SQL connection is closed | No | 2800 |
| flush_size | Number | Maximum number of entries to buffer before sending to SQL - if this is reached before idle_flush_time | No | 1000 |
| max_flush_exceptions | Number | Number of sequential flushes which cause an exception, before the set of events are discarded. Set to a value less than 1 if you never want it to stop. This should be carefully configured with respect to retry_initial_interval and retry_max_interval, if your SQL server is not highly available | No | 10 |
| retry_initial_interval | Number | Number of seconds before the initial retry in the event of a failure. On each failure it will be doubled until it reaches retry_max_interval | No | 2 |
| retry_max_interval | Number | Maximum number of seconds between each retry | No | 128 |

## Example configurations
Example logstash configurations, can now be found in the examples directory. Where possible we try to link every configuration with a tested jar.

If you have a working sample configuration, for a DB thats not listed, pull requests are welcome.

## Development and Running tests
For development tests are recommended to run inside a virtual machine (Vagrantfile is included in the repo), as it requires
access to various database engines and could completely destroy any data in a live system.

If you have vagrant available (this is temporary whilst I'm hacking on v5 support. I'll make this more streamlined later):
  - `vagrant up`
  - `vagrant ssh`
  - `cd /vagrant`
  - `gem install bundler`
  - `cd /vagrant && bundle install && bundle exec rake vendor && bundle exec rake install_jars`
  - `./scripts/travis-before_script.sh && source ./scripts/travis-variables.sh`
  - `bundle exec rspec`

## Releasing
  - `bundle exec rake install_jars`
  - `gem build logstash-output-jdbc.gemspec`
  - `gem push`
