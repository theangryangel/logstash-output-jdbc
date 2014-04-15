logstash-jdbc
=============
JDBC output plugin for Logstash.
This plugin is provided as an external plugin and is not part of the Logstash project.

Warning
-------
This has not yet been extensively tested with all JDBC drivers and may not yet work for you.

Installation
------------
  - Copy logstash directory contents into your logstash installation.
  - Add JDBC jar files to vendor/jar/jdbc in your logstash installation
  - Configure

Example configuration
---------------------
```output {
	jdbc {
		driver_class => 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
		connection_string => "jdbc:sqlserver://server:1433;databaseName=databasename;user=username;password=password;autoReconnect=true;"
		statement => [ "INSERT INTO filezilla (host, connection_id, timestamp, username, client, command) VALUES(?, ?, ?, ?, ?, ?)", "%{host}", "%{connection_id}", "%{timestamp}", "%{username}", "%{client}", "%{command}" ]
	}
}```

/* vim: set ts=4 sw=4 tw=0 :*/
