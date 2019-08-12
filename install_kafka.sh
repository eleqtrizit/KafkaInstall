#!/bin/sh

zookeeper_key=zookeeper.connect
zookeeper_val=localhost:2181
zookeeper_master=localhost:2181

broker_key=broker.id
broker_val=0
validated_network=192.168.0.0/24

# originally based on https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04#step-1-—-creating-a-user-for-kafka
# now with automation and major modifications!

get_network(){
    echo
    echo Enter Network \(i.e. 192.168.0.0/24\):
    read -r network
    validated_network=$(echo "$network" | perl -ne 'if ($_ =~ /^(\d+\.\d+\.\d+\.\d+\/\d+)$/){print "$1\n"}else{print "0\n"}')
    if [ "$validated_network" = 0 ]
    then
        echo Error in the network format entered.  Expected xxx.xxx.xxx.xxx/yy, received "$network"
        exit
    fi
}

search_for_kafka_zookepper(){
    echo
    echo Searching for existing Zookeepers...
    val=$(nmap $validated_network -p 2181 --open -oG - | grep Ports | perl -ne 'if ($_ =~ /Host: (\d+\.\d+\.\d+\.\d+).*?Ports: (\d+)/) {print "$1:$2\n"}')
    if [ -n "$val" ]
    then
        zookeeper_val=$val
    fi
    echo "$zookeeper_key" set to "$zookeeper_val"
}

search_for_kafka_brokers(){
    echo
    echo Searching for existing Brokers...
    broker_val=$(nmap $validated_network -p 9092 --open -oG - | grep Ports | perl -ne 'if ($_ =~ /Host: (\d+\.\d+\.\d+\.\d+).*?Ports: (\d+)/) {print "$1:$2\n"}' | wc -l)
    echo "$broker_key" set to "$broker_val"
}

update_packages() {
    echo
    echo Update Packages and Install Dependencies

    echo Updating packages...
    sudo apt update
    sudo apt -y upgrade

    echo Installing Dependencies XMLLint, Java JDK, Nmap...
    sudo apt -y install libxml2-utils openjdk-11-jdk-headless nmap
}


setup_kafka_user(){
    echo
    echo Setting up user Kafka

    clone_dir=$(pwd)
    cd || exit
    sudo useradd kafka -m
    echo
    echo Enter password for user kafka:
    sudo passwd kafka
    sudo adduser kafka sudo
}

download_kafka(){
    echo
    echo Downloading and Extracting Kafka Binaries

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
    rm kafka.tgz
}

configure_kafka_with_zookeeper(){
    echo
    echo Configuring Kafka Server

    echo >> config/server.properties
    echo delete.topic.enable=true >> config/server.properties
    cd || exit
    sudo mv kafka /home/kafka
    sudo chown -R kafka:kafka /home/kafka/kafka
}

configure_kafka_broker_only(){
    echo
    echo Reconfiguring Kafka as broker to "$zookeeper_val"

    echo >> config/server.properties
    echo delete.topic.enable=true >> config/server.properties
    # swap default broker key
    sed -i "s/$broker_key=0/$broker_key=$broker_val/" config/server.properties
    # swap default zookeeper address
    sed -i "s/$zookeeper_key=$zookeeper_master/$zookeeper_key=$zookeeper_val/" config/server.properties
    cd || exit
    sudo mv kafka /home/kafka
    sudo chown -R kafka:kafka /home/kafka/kafka
}


install_kafka_services(){
    echo
    echo Creating SystemD Unit Files and Starting Server

    cd $clone_dir || exit
    sudo cp zookeeper.service /etc/systemd/system/
    sudo cp kafka.service /etc/systemd/system/

    sudo systemctl start kafka

    sudo journalctl -u kafka
    sudo systemctl enable kafka
}

lockdown_kafka_user(){
    sudo deluser kafka sudo
    sudo passwd kafka -l
    sudo su - kafka
    sudo passwd kafka -u
}

extra_steps(){
    echo
    echo Step 5 - To test, refer to:
    echo https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04#step-1-%E2%80%94-creating-a-user-for-kafka

    echo
    echo Step 6 - Install KafkaT
    echo run install_kafkat.sh on the machine you wish to use for monitoring
}



update_packages

# if you don't want user input for the network question, 
# uncomment below, and comment out get_network
#validated_network=192.168.100.0/24
get_network

search_for_kafka_zookepper
search_for_kafka_brokers
setup_kafka_user
download_kafka

# is there already a zookeeper?
if [ $zookeeper_val = $zookeeper_master ]
then
    configure_kafka_with_zookeeper
else
    configure_kafka_broker_only
fi

install_kafka_services
lockdown_kafka_user

cat /home/kafka/kafka/kafka.log
echo Kafka Installed
