# logstash-output-jdbc
This plugin is provided as an external plugin and is not part of the Logstash project.

This plugin allows you to output to SQL databases, using JDBC adapters.
See below for tested adapters, and example configurations.

This has not yet been extensively tested with all JDBC drivers and may not yet work for you.

This plugin does not bundle any JDBC jar files, and does expect them to be in a
particular location. Please ensure you read the 4 installation lines below.

## Versions
  - See v1.5 branch for logstash v1.5 
  - See v1.4 branch for logstash 1.4

## Installation
  - Run `bin/plugin install logstash-output-jdbc` in your logstash installation directory
  - Create the directory vendor/jar/jdbc in your logstash installation (`mkdir -p vendor/jar/jdbc/`)
  - Add JDBC jar files to vendor/jar/jdbc in your logstash installation
  - Configure

## Configuration options
  * driver_class, string, JDBC driver class to load
  * connection_string, string, JDBC connection string
  * statement, array, an array of strings representing the SQL statement to run. Index 0 is the SQL statement that is prepared, all other array entries are passed in as parameters (in order). A parameter may either be a property of the event (i.e. "@timestamp", or "host") or a formatted string (i.e. "%{host} - %{message}" or "%{message}"). If a key is passed then it will be automatically converted as required for insertion into SQL. If it's a formatted string then it will be passed in verbatim.
  * flush_size, number, default = 1000, number of entries to buffer before sending to SQL
  * idle_flush_time, number, default = 1, number of idle seconds before sending data to SQL, even if the flush_size has not been reached. If you modify this value you should also consider altering max_repeat_exceptions_time
  * max_repeat_exceptions, number, default = 5, number of times the same exception can repeat before we stop logstash. Set to a value less than 1 if you never want it to stop
  * max_repeat_exceptions_time, number, default = 30, maxium number of seconds between exceptions before they're considered "different" exceptions. If you modify idle_flush_time you should consider this value

## Example configurations
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
		driver_class => 'org.sqlite.JDBC'
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
		driver_class => 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
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
		driver_class => 'org.postgresql.Driver'
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
		driver_class => "oracle.jdbc.driver.OracleDriver"
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
		driver_class => "com.mysql.jdbc.Driver"
		connection_string => "jdbc:mysql://HOSTNAME/DATABASE?user=USER&password=PASSWORD"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```
