# Example: ODPS
With thanks to [@onesuper](https://github.com/onesuper)
```
input
{
    stdin { }
}
output {
    jdbc {
        driver_class => "com.aliyun.odps.jdbc.OdpsDriver"
        driver_auto_commit => false
        connection_string => "jdbc:odps:http://service.odps.aliyun.com/api?project=meta_dev&loglevel=DEBUG"
        username => "abcd"
        password => "1234"
        max_pool_size => 5
        flush_size => 10
        statement => [ "INSERT INTO test_logstash VALUES(?, ?, ?);", "host", "@timestamp", "message" ]
    }
}
```
