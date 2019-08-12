#!/bin/sh

sudo useradd kafka -m
sudo passwd kafka
sudo adduser kafka sudo


echo Updating packages...
apt update

echo Installing Java JDK...
apt -y openjdk-11-jdk-headless

echo Resolving Kafka download...
curl https://kafka.apache.org/downloads -o downloads.html
closer=$(xmllint --html downloads.html --xpath //a/@href 2>/dev/null | sed 's/ href="\([^"]*\)"/\1/g'  | grep closer | grep -v src | head -n 1)

curl $closer -o mirrors.html
kafka_download=$(xmllint --html mirrors.html --xpath //a/@href 2>/dev/null | sed 's/ href="\([^"]*\)"/\1/g' | grep -E 'https*://(mirror|apache)' | grep kafka | grep tgz | head -n 1)

echo Downloading Kafka...
curl $kafka_download -o kafka.tgz

mkdir ~/kafka
mv kafka.tgz ~/kafka
cd ~/kafka
tar -xvzf ~/Downloads/kafka.tgz --strip 1
cd 
sudo mv kafka /home/kafka
sudo chown -R kafka:kafka /home/kafka/kafka
echo delete.topic.enable=true > ~/kafka/config/server.properties

sudo cp zookeeper.service /etc/systemd/system/
sudo cp kafka.service /etc/systemd/system/

sudo systemctl start kafka

sudo journalctl -u kafka
sudo systemctl enable kafka


