#!/bin/bash

sudo timedatectl set-timezone Europe/Oslo

# add in path
echo 'export PATH="$PATH:/home/f_etlbroker/kafka/bin/"' | tee --append ~/.bashrc

# Packages
sudo apt-get update && \
      sudo yum -y install wget ca-certificates zip net-tools vim nano tar netcat tmux

# Java Open JDK 8
sudo apt-get -y install default-jdk
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sudo sysctl vm.swappiness=1
echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf

# Add hosts entries (mocking DNS) - put relevant IPs here
echo "10.80.0.115 kafka001
10.80.0.115 zookeeper001
10.80.0.116 kafka002
10.80.0.116 zookeeper002
10.80.0.117 kafka003
10.80.0.117 zookeeper003
10.80.0.115 kafka1
10.80.0.115 zookeeper1
10.80.0.116 kafka2
10.80.0.116 zookeeper2
10.80.0.117 kafka3
10.80.0.117 zookeeper3" | sudo tee --append /etc/hosts

# No renaming of windows in tmux
echo "set-option -g allow-rename off" | tee --append ~/.tmux.conf

# download Zookeeper and Kafka. Recommended is latest Kafka (0.10.2.1) and Scala 2.12
wget http://apache.mirror.digitalpacific.com.au/kafka/0.10.2.1/kafka_2.12-0.10.2.1.tgz
tar -xvzf kafka_2.12-0.10.2.1.tgz
rm kafka_2.12-0.10.2.1.tgz
mv kafka_2.12-0.10.2.1 kafka
cd kafka/
# Zookeeper quickstart
cat config/zookeeper.properties
bin/zookeeper-server-start.sh config/zookeeper.properties
# binding to port 2181 -> you're good. Ctrl+C to exit

# Testing Zookeeper install
# Start Zookeeper in the background
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
bin/zookeeper-shell.sh localhost:2181
ls /
# demonstrate the use of a 4 letter word
echo "ruok" | nc localhost 2181 ; echo

# Install Zookeeper boot scripts
zookeeper.service file

# verify it's stopped
nc -vz localhost 2181
# start zookeeper
sudo service zookeeper start
# verify it's started
nc -vz localhost 2181
echo "ruok" | nc localhost 2181 ; echo
# check the logs
cat logs/zookeeper.out
cat /home/f_etlbroker/kafka/logs/server.log
tail -f /home/f_etlbroker/kafka/logs/server.log


PJA 