# Example: Mysql
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
