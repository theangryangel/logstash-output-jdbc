# logstash-output-jdbc 

[![Build Status](https://travis-ci.org/theangryangel/logstash-output-jdbc.svg?branch=master)](https://travis-ci.org/theangryangel/logstash-output-jdbc) [![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=the_angry_angel&url=https://github.com/the_angry_angel/logstash-output-jdbc&title=logstash-output-jdbc&language=&tags=github&category=software)

This plugin is provided as an external plugin and is not part of the Logstash project.

This plugin allows you to output to SQL databases, using JDBC adapters.
See below for tested adapters, and example configurations.

This has not yet been extensively tested with all JDBC drivers and may not yet work for you.

If you do find this works for a JDBC driver without an example, let me know and provide a small example configuration if you can.

This plugin does not bundle any JDBC jar files, and does expect them to be in a
particular location. Please ensure you read the 4 installation lines below.

## Support & release schedule
I no longer have time at work to maintain this plugin in step with Logstash's releases, and I am not completely immersed in the Logstash ecosystem. If something is broken for you I will do my best to help, but I cannot guarantee timeframes.

Pull requests are always welcome. 

## Changelog
See CHANGELOG.md

## Versions
Released versions are available via rubygems, and typically tagged.

For development:
  - See master branch for logstash v5 & v6 :warning: This is untested under Logstash 6.3 at this time, and there has been 1 unverified report of an issue. Please use at your own risk until I can find the time to evaluate and test 6.3.
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

| Option                       | Type             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Required? | Default |
| ------                       | ----             | -----------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | --------- | ------- |
| driver_class                 | String           | Specify a driver class if autoloading fails                                                                                                                                                                                                                                                                                                                                                                                                                                                   | No        |         |
| driver_auto_commit           | Boolean          | If the driver does not support auto commit, you should set this to false                                                                                                                                                                                                                                                                                                                                                                                                                      | No        | True    |
| driver_jar_path              | String           | File path to jar file containing your JDBC driver. This is optional, and all JDBC jars may be placed in $LOGSTASH_HOME/vendor/jar/jdbc instead.                                                                                                                                                                                                                                                                                                                                               | No        |         |
| connection_string            | String           | JDBC connection URL                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Yes       |         |
| connection_test              | Boolean          | Run a JDBC connection test. Some drivers do not function correctly, and you may need to disable the connection test to supress an error. Cockroach with the postgres JDBC driver is such an example.                                                                                                                                                                                                                                                                                          | No        | Yes     |
| connection_test_query        | String           | Connection test and init query string, required for some JDBC drivers that don't support isValid(). Typically you'd set to this "SELECT 1"                                                                                                                                                                                                                                                                                                                                                    | No        |         |
| username                     | String           | JDBC username - this is optional as it may be included in the connection string, for many drivers                                                                                                                                                                                                                                                                                                                                                                                             | No        |         |
| password                     | String           | JDBC password - this is optional as it may be included in the connection string, for many drivers                                                                                                                                                                                                                                                                                                                                                                                             | No        |         |
| statement                    | Array            | An array of strings representing the SQL statement to run. Index 0 is the SQL statement that is prepared, all other array entries are passed in as parameters (in order). A parameter may either be a property of the event (i.e. "@timestamp", or "host") or a formatted string (i.e. "%{host} - %{message}" or "%{message}"). If a key is passed then it will be automatically converted as required for insertion into SQL. If it's a formatted string then it will be passed in verbatim. | Yes       |         |
| unsafe_statement             | Boolean          | If yes, the statement is evaluated for event fields - this allows you to use dynamic table names, etc. **This is highly dangerous** and you should **not** use this unless you are 100% sure that the field(s) you are passing in are 100% safe. Failure to do so will result in possible SQL injections. Example statement: [ "insert into %{table_name_field} (column) values(?)", "fieldname" ]                                                                                            | No        | False   |
| max_pool_size                | Number           | Maximum number of connections to open to the SQL server at any 1 time                                                                                                                                                                                                                                                                                                                                                                                                                         | No        | 5       |
| connection_timeout           | Number           | Number of milliseconds before a SQL connection is closed                                                                                                                                                                                                                                                                                                                                                                                                                                           | No        | 10000   |
| flush_size                   | Number           | Maximum number of entries to buffer before sending to SQL - if this is reached before idle_flush_time                                                                                                                                                                                                                                                                                                                                                                                         | No        | 1000    |
| max_flush_exceptions         | Number           | Number of sequential flushes which cause an exception, before the set of events are discarded. Set to a value less than 1 if you never want it to stop. This should be carefully configured with respect to retry_initial_interval and retry_max_interval, if your SQL server is not highly available                                                                                                                                                                                         | No        | 10      |
| retry_initial_interval       | Number           | Number of seconds before the initial retry in the event of a failure. On each failure it will be doubled until it reaches retry_max_interval                                                                                                                                                                                                                                                                                                                                                  | No        | 2       |
| retry_max_interval           | Number           | Maximum number of seconds between each retry                                                                                                                                                                                                                                                                                                                                                                                                                                                  | No        | 128     |
| retry_sql_states             | Array of strings | An array of custom SQL state codes you wish to retry until `max_flush_exceptions`. Useful if you're using a JDBC driver which returns retry-able, but non-standard SQL state codes in it's exceptions.                                                                                                                                                                                                                                                                                        | No        | []      |
| event_as_json_keyword        | String           | The magic key word that the plugin looks for to convert the entire event into a JSON object. As Logstash does not support this out of the box with it's `sprintf` implementation, you can use whatever this field is set to in the statement parameters                                                                                                                                                                                                                                       | No        | @event  |
| enable_event_as_json_keyword | Boolean          | Enables the magic keyword set in the configuration option `event_as_json_keyword`. Without this enabled the plugin will not convert the `event_as_json_keyword` into JSON encoding of the entire event.                                                                                                                                                                                                                                                                                       | No        | False   |

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
  - Update Changelog
  - Bump version in gemspec
  - Commit
  - Create tag `git tag v<version-number-in-gemspec>`
  - `bundle exec rake install_jars`
  - `bundle exec rake pre_release_checks`
  - `gem build logstash-output-jdbc.gemspec`
  - `gem push`
