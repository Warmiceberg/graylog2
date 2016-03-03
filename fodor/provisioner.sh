#!/bin/bash
wget https://packages.graylog2.org/repo/packages/graylog-1.3-repository-ubuntu14.04_latest.deb
dpkg -i graylog-1.3-repository-ubuntu14.04_latest.deb
apt-get install apt-transport-https
apt-get update
apt-get install graylog-server graylog-web

sudo start graylog-server
sudo start graylog-web
