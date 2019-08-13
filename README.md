# Kafka Install for Kafka 2.1 or greater
### Tested on Ubuntu 18.04 Server

This is a helper shell script to quickly get a Kafka cluster online.

This script is fundamentally fragile.  As of today (8/13/19) it works great.  In the future, it could break.  For example, if Apache Kafka's download page fundamentally changes it's format, it won't download Kafka. However, every part of this script is in functions, so you should be able to debug this by simply running them one at a time.

It is based on the instructions found here:<br>
https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04

To create a cluster with this script, run the script one machine at a time. The foundations are here, however, to run this in full automation if it were to be controlled and configured by a master server, eliminating the few parts that still require human input.

After cloning the repo, run install_kafka.sh

The script will follow these steps:
* update and upgrade w/ apt
* Install dependencies
* Gather your network address range.
  * e.g. 192.168.0.1/24
* Gather your Zookeeper address(es).  
  * Before it does this, it will first scan the network for any existing Zookeepers.  If none are found, it will default to localhost:2181
* Count the # of brokers on the network.  
  * This is to make a unique broker.id.
  * **This is mostly for testing.  This would not be a reliable way to assign a broker id in a production environment!**
* The script will create a user named "kafka" to run the service
* Download Kafka
  * Parse the Apache Kafka page for the latest download
  * Pull it automatically
* Configure Kafka
  * If only Zookeeper, set zookeeper address to localhost:2181
  * else, set zookeeper address to whatever you the user enters when prompted
* Install Kafka services
* Strip rights away from Kafka user
* Show the log of Kafka starting
