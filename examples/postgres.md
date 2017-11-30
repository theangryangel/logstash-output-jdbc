# Example 1: Postgres
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

# Example 2: If the previous example doesn't work (i.e. connection errors)

> Tested with https://jdbc.postgresql.org/download/postgresql-42.1.4.jre7.jar saved to /opt/logstash/vendor/jar/jdbc/
> Not sure if the `connection_test => false` is necessary or not.

```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => 'jdbc:postgresql://hostname:5432/database'
		connection_test => false
		username => 'username'
		password => 'password'
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```
