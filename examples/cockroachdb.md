# Example: CockroachDB
  - Tested using postgresql-9.4.1209.jre6.jar
  - **Warning** cockroach is known to throw a warning on connection test (at time of writing), thus the connection test is explicitly disabled.

```
input
{
    stdin { }
}
output {
    jdbc {
        driver_jar_path => '/opt/postgresql-9.4.1209.jre6.jar'
        connection_test => false
        connection_string => 'jdbc:postgresql://127.0.0.1:26257/test?user=root'
        statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, CAST (? AS timestamp), ?)", "host", "@timestamp", "message" ]
    }
}
```
