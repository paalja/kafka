#!/bin/bash

# we can create topics with replication-factor 3 now!
kafka-topics.sh --zookeeper zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka --create --topic asdf3 --replication-factor 3 --partitions 3

# we can publish data to Kafka using the bootstrap server list!
kafka-console-producer.sh --broker-list kafka1:9092,kafka2:9092,kafka3:9092 --topic second_topic

# we can read data using any broker too!
kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic asdf3 --from-beginning

# we can create topics with replication-factor 3 now!
kafka-topics.sh --zookeeper zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka --create --topic third_topic --replication-factor 3 --partitions 3

# let's list topics
kafka-topics.sh --zookeeper zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka --list

# publish some data
kafka-console-producer.sh --broker-list kafka1:9092,kafka2:9092,kafka3:9092 --topic third_topic

# let's delete that topic
kafka-topics.sh --zookeeper zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka --delete --topic third_topic

# it should be deleted shortly:
kafka-topics.sh --zookeeper zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/kafka --list



--max-messages

kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic dns_v2 --max-messages 20
kafka-console-consumer --bootstrap-server localhost:9092 --topic dns_v2 --max-messages 20


BOOTSTRAP_SERVERS="SSL://st-linapp1103.st.statoil.no:9093,st-linapp1102.st.statoil.no:9093,st-linapp1101.st.statoil.no:9093" 
/usr/bin/kafka-console-consumer --bootstrap-server ${BOOTSTRAP_SERVERS} --consumer.config /etc/kafka/kafka-tools.properties --max-messages 1 --topic dns_v2
/usr/bin/kafka-console-consumer --bootstrap-server ${BOOTSTRAP_SERVERS} --consumer.config /etc/kafka/kafka-tools.properties --max-messages 1 --topic paloalto_v2 
