#!/bin/sh

clone_dir=$(pwd)
cd || exit
sudo useradd kafka -m
echo Enter password for user kafka:
sudo passwd kafka
sudo adduser kafka sudo


echo Updating packages...
sudo apt update
sudo apt -y upgrade

echo Installing XMLLint...
sudo apt -y install libxml2-utils

echo Installing Java JDK...
sudo apt -y install openjdk-11-jdk-headless

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
tar xvzf kafka.tgz --strip 1

echo delete.topic.enable=true >> config/server.properties
cd || exit
sudo mv kafka /home/kafka
sudo chown -R kafka:kafka /home/kafka/kafka

cd $clone_dir || exit
sudo cp zookeeper.service /etc/systemd/system/
sudo cp kafka.service /etc/systemd/system/

sudo systemctl start kafka

sudo journalctl -u kafka
sudo systemctl enable kafka

