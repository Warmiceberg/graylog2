#!/bin/bash
apt-get install -y python-software-properties debconf-utils pwgen


add-apt-repository -y ppa:webupd8team/java
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
apt-get -y update

#MongoDB
apt-get -y install mongodb-org

# Install java
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
apt-get -y install oracle-java8-installer


# Install Elasticsearch
apt-get -y install elasticsearch
sed -i -e 's/# cluster.name: my-application$/cluster.name: graylog/g' /etc/elasticsearch/elasticsearch.yml

service elasticsearch restart
update-rc.d elasticsearch defaults 95 10

# Install graylog-server
wget https://packages.graylog2.org/repo/packages/graylog-2.1-repository_latest.deb
dpkg -i graylog-2.1-repository_latest.deb
apt-get -y update
apt-get install apt-transport-https
apt-get install graylog-server

# graylog-server config file
sed -i -e "s/rest_listen_uri = http:\/\/127.0.0.1:12900\//rest_listen_uri = http:\/\/${IPV4}:12900\//g" /etc/graylog/server/server.conf
sed -i -e "s/#web_listen_uri = http:\/\/127.0.0.1:9000\//web_listen_uri = http:\/\/${IPV4}:9000\//g" /etc/graylog/server/server.conf

echo "elasticsearch_cluster_name = graylog" >> /etc/graylog/server/server.conf
echo "elasticsearch_discovery_zen_ping_multicast_enabled = false" >> /etc/graylog/server/server.conf
echo "elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300" >> /etc/graylog/server/server.conf
sed -i -e 's/elasticsearch_shards = 4/elasticsearch_shards = 1/g' /etc/graylog/server/server.conf

SECRET=$(pwgen -s 96 1)
sed -i -e 's/password_secret =.*/password_secret = '$SECRET'/' /etc/graylog/server/server.conf

PASSWORD=$(echo -n $ADMIN_PASSWORD | shasum -a 256 | awk '{print $1}')
sed -i -e 's/root_password_sha2 =.*/root_password_sha2 = '$PASSWORD'/' /etc/graylog/server/server.conf

rm -f /etc/init/graylog-server.override
start graylog-server
