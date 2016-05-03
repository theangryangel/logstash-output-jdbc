# Example: SQLite3
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
        driver_class => "org.sqlite.JDBC"
		connection_string => 'jdbc:sqlite:test.db'
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
	}
}
```
