#!/bin/bash
wget http://search.maven.org/remotecontent?filepath=org/apache/derby/derby/10.12.1.1/derby-10.12.1.1.jar -O /tmp/derby.jar

sudo apt-get install mysql-server postgresql-client postgresql -qq -y
echo "create database logstash; grant all privileges on logstash.* to 'logstash'@'localhost' identified by 'logstash'; flush privileges;" | sudo -u root mysql
echo "create user logstash PASSWORD 'logstash'; create database logstash; grant all privileges on database logstash to logstash;" | sudo -u postgres psql

wget http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar -O /tmp/mysql.jar
wget http://search.maven.org/remotecontent?filepath=org/xerial/sqlite-jdbc/3.8.11.2/sqlite-jdbc-3.8.11.2.jar -O /tmp/sqlite.jar
wget http://central.maven.org/maven2/org/postgresql/postgresql/42.1.4/postgresql-42.1.4.jar -O /tmp/postgres.jar
