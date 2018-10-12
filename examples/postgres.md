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

> Tested with the following JARs saved to `/opt/logstash/vendor/jar/jdbc/` :
> - **For Logstash 2.x+ using Java 7:**
>
>   https://jdbc.postgresql.org/download/postgresql-42.1.4.jre7.jar
> - **For Logstash 6.x+ using Java 8:**
>
>   https://jdbc.postgresql.org/download/postgresql-42.2.5.jar

```
input
{
	stdin { }
}
output {
	jdbc {
		connection_string => 'jdbc:postgresql://hostname:5432/database'
		username => 'username'
		password => 'password'
		statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
	}
}
```
