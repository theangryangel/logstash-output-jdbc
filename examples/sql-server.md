# Example: SQL Server
  * Tested using http://msdn.microsoft.com/en-gb/sqlserver/aa937724.aspx
  * Known to be working with Microsoft SQL Server Always-On Cluster (see https://github.com/theangryangel/logstash-output-jdbc/issues/37). With thanks to [@phr0gz](https://github.com/phr0gz)
```
input
{
	stdin { }
}
output {
	jdbc {
		driver_jar_path => '/opt/sqljdbc42.jar'
		connection_string => "jdbc:sqlserver://server:1433;databaseName=databasename;user=username;password=password"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
	}
	
}
```

Another example, with mixed static strings and parameters, with thanks to [@MassimoSporchia](https://github.com/MassimoSporchia)
```
input
{
	stdin { }
}
output {
jdbc {
		driver_jar_path => '/opt/sqljdbc42.jar'
		connection_string => "jdbc:sqlserver://server:1433;databaseName=databasename;user=username;password=password"
		statement => [ "INSERT INTO log (host, timestamp, message, comment) VALUES(?, ?, ?, 'static string')", "host", "@timestamp", "message" ]
	}
}
```

Note: Windows users need to use windows paths (e.g. `C:\lib\mssql-jdbc-6.4.0.jre8.jar`). Paths with forward slashes will not work.
