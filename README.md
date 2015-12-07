# logstash-output-jdbc
This plugin is provided as an external plugin and is not part of the Logstash project.

This plugin allows you to output to SQL databases, using JDBC adapters.
See below for tested adapters, and example configurations.

This has not yet been extensively tested with all JDBC drivers and may not yet work for you.

If you do find this works for a JDBC driver not listed, let me know and provide a small example configuration.

This plugin does not bundle any JDBC jar files, and does expect them to be in a
particular location. Please ensure you read the 4 installation lines below.

## Headlines
  - Support for connection pooling added in 0.2.0
  - Support for unsafe statement handling (allowing dynamic queries) in 0.2.0 
  - Altered exception handling to now count sequential flushes with exceptions thrown in 0.2.0 

## Versions
  - See master branch for logstash v2+
  - See v1.5 branch for logstash v1.5 
  - See v1.4 branch for logstash 1.4

## Installation
  - Run `bin/plugin install logstash-output-jdbc` in your logstash installation directory
  - Now either:
    - Use driver_class in your configuraton to specify a path to your jar file
  - Or:
    - Create the directory vendor/jar/jdbc in your logstash installation (`mkdir -p vendor/jar/jdbc/`)
    - Add JDBC jar files to vendor/jar/jdbc in your logstash installation
  - And then configure (examples below)

## Running tests
Assuming valid JDBC jar, and jruby is setup and installed, and you have issued `jruby -S bundle install` in the development directory
  - `SQL_JAR=path/to/your.jar jruby -S bundle exec rspec`
If you need to provide username and password you may do this via the environment variables `SQL_USERNAME` and `SQL_PASSWORD`.

Tests are not yet 100% complete.

## Configuration options

| Option | Type | Description | Required? | Default |
| ------ | ---- | ----------- | --------- | ------- |
| driver_path | String | File path to jar file containing your JDBC driver. This is optional, and all JDBC jars may be placed in $LOGSTASH_HOME/vendor/jar/jdbc instead. | No | |
| connection_string | String | JDBC connection URL | Yes | |
| username | String | JDBC username - this is optional as it may be included in the connection string, for many drivers | No | |
| password | String | JDBC password - this is optional as it may be included in the connection string, for many drivers | No | |
| statement | Array | An array of strings representing the SQL statement to run. Index 0 is the SQL statement that is prepared, all other array entries are passed in as parameters (in order). A parameter may either be a property of the event (i.e. "@timestamp", or "host") or a formatted string (i.e. "%{host} - %{message}" or "%{message}"). If a key is passed then it will be automatically converted as required for insertion into SQL. If it's a formatted string then it will be passed in verbatim. | Yes |  |
| unsafe_statement | Boolean | If yes, the statement is evaluated for event fields - this allows you to use dynamic table names, etc. **This is highly dangerous** and you should **not** use this unless you are 100% sure that the field(s) you are passing in are 100% safe. Failure to do so will result in possible SQL injections. Please be aware that there is also a potential performance penalty as each event must be evaluated and inserted into SQL one at a time, where as when this is false multiple events are inserted at once. Example statement: [ "insert into %{table_name_field} (column) values(?)", "fieldname" ] | No | False |
| max_pool_size | Number | Maximum number of connections to open to the SQL server at any 1 time | No | 5 |
| connection_timeout | Number | Number of seconds before a SQL connection is closed | No | 2800 |
| flush_size | Number | Maximum number of entries to buffer before sending to SQL - if this is reached before idle_flush_time | No | 1000 |
| idle_flush_time | Number | Number of idle seconds before sending data to SQL - even if the flush_size has not yet been reached | No | 1 |
| max_flush_exceptions | Number | Number of sequential flushes which cause an exception, before we stop logstash. Set to a value less than 1 if you never want it to stop. This should be carefully configured with relation to idle_flush_time if your SQL instance is not highly available. | No | 0 |

## Example configurations
If you have a working sample configuration, for a DB thats not listed, pull requests are welcome.

### SQLite3
  * Tested using https://bitbucket.org/xerial/sqlite-jdbc
  * SQLite setup - `echo "CREATE table log (host text, timestamp datetime, message text);" | sqlite3 test.db`
```
input
{
	stdin { }
}
output {
	stdout { }

	jdbc {
		connection_string => 'jdbc:sqlite:test.db'
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
	}
}
```

### SQL Server
  * Tested using http://msdn.microsoft.com/en-gb/sqlserver/aa937724.aspx
```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => "jdbc:sqlserver://server:1433;databaseName=databasename;user=username;password=password;autoReconnect=true;"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
	}
}
```

### Postgres
With thanks to [@roflmao](https://github.com/roflmao)
```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => 'jdbc:postgresql://hostname:5432/database?user=username&password=password'
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```

### Oracle
With thanks to [@josemazo](https://github.com/josemazo)
  * Tested with Express Edition 11g Release 2
  * Tested using http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html (ojdbc6.jar)
```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => "jdbc:oracle:thin:USER/PASS@HOST:PORT:SID"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```

### Mysql
With thanks to [@jMonsinjon](https://github.com/jMonsinjon) 
  * Tested with Version 14.14 Distrib 5.5.43, for debian-linux-gnu (x86_64)
  * Tested using http://dev.mysql.com/downloads/file.php?id=457911 (mysql-connector-java-5.1.36-bin.jar)
```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => "jdbc:mysql://HOSTNAME/DATABASE?user=USER&password=PASSWORD"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```

### MariaDB
  * Tested with Ubuntu 14.04.3 LTS, Server version: 10.1.9-MariaDB-1~trusty-log mariadb.org binary distribution
  * Tested using https://downloads.mariadb.com/enterprise/tqge-whfa/connectors/java/connector-java-1.3.2/mariadb-java-client-1.3.2.jar (mariadb-java-client-1.3.2.jar)
```
input
{
    stdin { }
}
output {
    jdbc {
        connection_string => "jdbc:mariadb://HOSTNAME/DATABASE?user=USER&password=PASSWORD"
        statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
    }

}
```

### Apache Phoenix (HBase SQL)
  * Tested with Ubuntu 14.04.03 / Logstash 2.1 / Apache Phoenix 4.6
  * <!> HBase and Zookeeper must be both accessible from logstash machine <!>
```
input
{
    stdin { }
}
output {
    jdbc {
        connection_string => "jdbc:phoenix:ZOOKEEPER_HOSTNAME"
        statement => [ "UPSERT INTO EVENTS log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
    }

}
```
