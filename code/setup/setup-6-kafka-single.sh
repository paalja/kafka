#!/bin/bash

# Add file limits configs - allow to open 100,000 file descriptors from kafka course
#echo "* hard nofile 100000
#* soft nofile 100000" | sudo tee --append /etc/security/limits.conf

# Add file limits configs - allow to open 65,535 file descriptors as in Prod cluster
echo "Added by PJA 30.April2020
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535" | sudo tee --append /etc/security/limits.conf

# reboot for the file limit to be taken into account
sudo reboot
sudo service zookeeper start
sudo chown -R ubuntu:ubuntu /data/kafka

# edit kafka configuration
rm config/server.properties
nano config/server.properties

# launch kafka
bin/kafka-server-start.sh config/server.properties

# Install Kafka boot scripts
# vi /etc/systemd/system/kafka.service

# start kafka
sudo systemctl start kafka
# verify it's working
nc -vz localhost 9092
# look at the server logs
cat /home/f_etlbroker/kafka/logs/kafka.log


# create a topic
bin/kafka-topics.sh --zookeeper zookeeper1:2181/kafka --create --topic asdf3 --replication-factor 1 --partitions 3
# produce data to the topic
bin/kafka-console-producer.sh --broker-list kafka1:9092 --topic asdf3
hi
hello
(exit)
# read that data
bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092 --topic asdf3 --from-beginning
# list kafka topics
bin/kafka-topics.sh --zookeeper zookeeper1:2181/kafka --list
