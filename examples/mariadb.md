# Example: MariaDB
  * Tested with Ubuntu 14.04.3 LTS, Server version: 10.1.9-MariaDB-1~trusty-log mariadb.org binary distribution
  * Tested using https://downloads.mariadb.com/enterprise/tqge-whfa/connectors/java/connector-java-1.3.2/mariadb-java-client-1.3.2.jar (mariadb-java-client-1.3.2.jar)
```
input
{
    stdin { }
}
output {
    jdbc {
        connection_string => "jdbc:mariadb://HOSTNAME/DATABASE?user=USER&password=PASSWORD"
        statement => [ "INSERT INTO log (host, timestamp, message) VALUES(?, ?, ?)", "host", "@timestamp", "message" ]
    }

}
```
