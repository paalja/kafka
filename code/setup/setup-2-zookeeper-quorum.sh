#!/bin/bash
# create data dictionary for zookeeper
sudo mkdir -p /data/disk7/zookeeper
sudo chown -R f_etlbroker:f_etlbroker /data/disk7/zookeeper
# declare the server's identity
echo "1" > /data/disk7/zookeeper/myid
# edit the zookeeper settings
rm /home/f_etlbroker/kafka/config/zookeeper.properties
vi /home/f_etlbroker/kafka/config/zookeeper.properties
# restart the zookeeper service
sudo service zookeeper stop
sudo service zookeeper start
# observe the logs - need to do this on every machine
cat /home/f_etlbroker/kafka/logs/zookeeper.out | head -100
nc -vz localhost 2181
nc -vz localhost 2888
nc -vz localhost 3888
echo "ruok" | nc localhost 2181 ; echo
echo "stat" | nc localhost 2181 ; echo
bin/zookeeper-shell.sh localhost:2181
# not happy
ls /
