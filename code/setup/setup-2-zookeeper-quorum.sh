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
cat /data/disk7/zookeeper/logs.out | head -100
cat /home/f_etlbroker/kafka/logs/zookeeper.out | head -100

nc -vz localhost 2181
nc -vz localhost 2888
nc -vz localhost 3888
echo "ruok" | nc zookeeper1 2181 ; echo; echo "ruok" | nc zookeeper2 2181 ; echo ; echo "ruok" | nc zookeeper3 2181 ; echo
echo "stat" | nc zookeeper1 2181 ; echo; echo "stat" | nc zookeeper2 2181 ; echo ; echo "stat" | nc zookeeper3 2181 ; echo
echo "mntr" | nc zookeeper1 2181 ; echo; echo "mntr" | nc zookeeper2 2181 ; echo ; echo "mntr" | nc zookeeper3 2181 ; echo

echo "ruok" | nc st-linapp1101.st.statoil.no 2181 ; echo; echo "ruok" | nc st-linapp1102.st.statoil.no 2181 ; echo ; echo "ruok" | nc st-linapp1103.st.statoil.no 2181 ; echo
echo "stat" | nc st-linapp1101.st.statoil.no 2181 ; echo; echo "stat" | nc st-linapp1102.st.statoil.no 2181 ; echo ; echo "stat" | nc st-linapp1103.st.statoil.no 2181 ; echo
echo "mntr" | nc st-linapp1101.st.statoil.no 2181 ; echo; echo "mntr" | nc st-linapp1102.st.statoil.no 2181 ; echo ; echo "mntr" | nc st-linapp1103.st.statoil.no 2181 ; echo

bin/zookeeper-shell.sh localhost:2181
# not happy
ls /
