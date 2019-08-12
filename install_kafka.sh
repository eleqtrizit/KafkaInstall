#!/bin/sh

zookeeper_key=zookeeper.connect
zookeeper_val=localhost:2181
broker_key=broker.id
broker_val=0

# originally based on https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04#step-1-—-creating-a-user-for-kafka
# now with automation and major modifications!

update_packages() {


}
echo
echo Step 0

echo Updating packages...
sudo apt update
sudo apt -y upgrade

echo Installing XMLLint...
sudo apt -y install libxml2-utils

echo Installing Java JDK...
sudo apt -y install openjdk-11-jdk-headless


echo
echo Step 1 -- Setting up user Kafka

clone_dir=$(pwd)
cd || exit
sudo useradd kafka -m
echo
echo Enter password for user kafka:
sudo passwd kafka
sudo adduser kafka sudo

echo
echo Step 2 -- Downloading and Extracting Kafka Binaries

echo Resolving Kafka download...
echo https://kafka.apache.org/downloads
curl https://kafka.apache.org/downloads -o downloads.html
closer=$(xmllint --html downloads.html --xpath //a/@href 2>/dev/null | sed 's/ href="\([^"]*\)"/\1\n/g'  | grep closer | grep -v src | head -n 1)

echo curl "$closer"
curl "$closer" -o mirrors.html
kafka_download=$(xmllint --html mirrors.html --xpath //a/@href 2>/dev/null | sed 's/ href="\([^"]*\)"/\1\n/g' | grep -E 'https?://(mirror|apache)' | grep kafka | grep tgz | head -n 1)

rm downloads.html mirrors.html

mkdir kafka
cd kafka || exit
echo curl "$kafka_download"
echo Downloading Kafka...
curl "$kafka_download" -o kafka.tgz
tar xzf kafka.tgz --strip 1

echo
echo Step 3 - Configuring Kafka Server

echo >> config/server.properties
echo delete.topic.enable=true >> config/server.properties
cd || exit
sudo mv kafka /home/kafka
sudo chown -R kafka:kafka /home/kafka/kafka


echo
echo Step 4 - Creating SystemD Unit Files and Starting Server

cd $clone_dir || exit
sudo cp zookeeper.service /etc/systemd/system/
sudo cp kafka.service /etc/systemd/system/

sudo systemctl start kafka

sudo journalctl -u kafka
sudo systemctl enable kafka



echo
echo Step 5 - To test, refer to:
echo https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04#step-1-%E2%80%94-creating-a-user-for-kafka

echo
echo Step 6 - Install KafkaT
echo run install_kafkat.sh on the machine you wish to use for monitoring



