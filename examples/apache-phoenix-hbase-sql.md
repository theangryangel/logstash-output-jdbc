# Example: Apache Phoenix (HBase SQL)
  * Tested with Ubuntu 14.04.03 / Logstash 2.1 / Apache Phoenix 4.6
  * <!> HBase and Zookeeper must be both accessible from logstash machine <!>
  * Please see apache-phoenix-thin-hbase-sql for phoenix-thin. The examples are different.
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
