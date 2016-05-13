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
		connection_string => "jdbc:sqlserver://server:1433;databaseName=databasename;user=username;password=password"
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
	}
}
```
