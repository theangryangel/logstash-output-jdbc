# Example: Oracle
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
