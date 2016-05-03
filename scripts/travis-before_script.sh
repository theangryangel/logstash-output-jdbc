#!/bin/bash
wget http://search.maven.org/remotecontent?filepath=org/apache/derby/derby/10.12.1.1/derby-10.12.1.1.jar -O /tmp/derby.jar

sudo apt-get install mysql-server -qq -y
echo "create database logstash_output_jdbc_test;" | mysql -u root

wget http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar -O /tmp/mysql.jar
wget http://search.maven.org/remotecontent?filepath=org/xerial/sqlite-jdbc/3.8.11.2/sqlite-jdbc-3.8.11.2.jar -O /tmp/sqlite.jar
