#!/bin/bash
sudo apt-get install -y python-software-properties debconf-utils pwgen


add-apt-repository ppa:webupd8team/java
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/elasticsearch/1.7/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-1.7.x.list
apt-get -y update

#MongoDB
apt-get -y install mongodb-org

# Install java
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get -y install oracle-java8-installer


# Install Elasticsearch
apt-get -y install elasticsearch
sed -i -e 's/#cluster.name: elasticsearch/cluster.name: graylog/g' /etc/elasticsearch/elasticsearch.yml
service elasticsearch restart
update-rc.d elasticsearch defaults 95 10

# Install graylog-server
wget https://packages.graylog2.org/repo/packages/graylog-1.3-repository-ubuntu14.04_latest.deb
dpkg -i graylog-1.3-repository-ubuntu14.04_latest.deb
apt-get -y update
apt-get install apt-transport-https
apt-get install graylog-server


# graylog-server config file
echo "rest_transport_uri = http://127.0.0.1:12900/" >> /etc/graylog/server/server.conf
echo "elasticsearch_cluster_name = graylog" >> /etc/graylog/server/server.conf
echo "elasticsearch_discovery_zen_ping_multicast_enabled = false" >> /etc/graylog/server/server.conf
echo "elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300" >> /etc/graylog/server/server.conf
sed -i -e 's/elasticsearch_shards = 4/elasticsearch_shards = 1/g' /etc/graylog/server/server.conf

SECRET=$(pwgen -s 96 1)
sed -i -e 's/password_secret =.*/password_secret = '$SECRET'/' /etc/graylog/server/server.conf

start graylog-server

# Install graylog-web
apt-get -y install graylog-web

SECRET=$(pwgen -s 96 1)
sed -i -e 's/application\.secret=""/application\.secret="'$SECRET'"/' /etc/graylog/web/web.conf
sed -i -e 's/graylog2-server.uris=""/graylog2-server.uris="http:\/\/127.0.0.1:12900\/"/g' /etc/graylog/web/web.conf
start graylog-web
