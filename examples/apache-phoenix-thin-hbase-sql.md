# Example: Apache Phoenix-Thin (HBase SQL)

**There are special instructions for phoenix-thin. Please read carefully!**

  * Tested with Logstash 5.1.1 / Apache Phoenix 4.9
  * HBase and Zookeeper must be both accessible from logstash machine
  * At time of writing phoenix-client does not include all the required jars (see https://issues.apache.org/jira/browse/PHOENIX-3476), therefore you must *not* use the driver_jar_path configuration option and instead:
    - `mkdir -p vendor/jar/jdbc` in your logstash installation path
    - copy `phoenix-queryserver-client-4.9.0-HBase-1.2.jar` from the phoenix distribution into this folder
    - download the calcite jar from https://mvnrepository.com/artifact/org.apache.calcite/calcite-avatica/1.6.0 and place it into your `vendor/jar/jdbc` directory
  * Use the following configuration as a base. The connection_test => false and connection_test_query are very important and should not be omitted. Phoenix-thin does not appear to support isValid and these are necessary for the connection to be added to the pool and be available.

```
input
{
    stdin { }
}
output {
    jdbc {
        connection_test => false
        connection_test_query => "select 1"
        driver_class => "org.apache.phoenix.queryserver.client.Driver"
        connection_string => "jdbc:phoenix:thin:url=http://localhost:8765;serialization=PROTOBUF"
        statement => [ "UPSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
    }

}
```
