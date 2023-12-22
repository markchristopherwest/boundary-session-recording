#!/bin/bash

# Log Everything
sudo touch /var/log/user-data.log
sudo chown root:adm /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
sudo apt-get update

# Install Services to Target
echo "Installing Postgres"

# Create an Postgres Instance
sudo apt-get install -y postgresql
sudo apt-get install -y postgresql-client
# Make Postgres Wide Open
echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/14/main/postgresql.conf
echo 'host    all             all              0.0.0.0/0                       md5' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf 
echo 'host    all             all              ::/0                            md5' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf 
echo 'host    replication     replication      192.168.56.0/32                 md5' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf 
sudo systemctl restart postgresql.service


# Create an Redis Instance
echo "Installing Redis"
sudo apt-get install -y redis-server

sudo systemctl stop redis-server
sed -e '/^supervised no/supervised systemd/' \
    -e 's/^# *bind 127\.0\.0\.1 ::1/bind 127.0.0.1 ::1' \
    /etc/redis/redis.conf >/etc/redis/redis.conf.new
sudo mv /etc/redis/redis.conf /etc/redis/redis.conf.$(date +%y%b%d-%H%M%S)
sudo mv /etc/redis/redis.conf.new /etc/redis/redis.conf
sudo systemctl start redis-server
sleep 1
if [[ "$( echo 'ping' | /usr/bin/redis-cli )" == "PONG" ]] ; then
    echo "ping worked"
else
    echo "ping FAILED"
fi
sudo systemctl status redis
sudo systemctl status redis-server

# # Create an MongoDB Instance
# echo "Installing MongoDB"
# curl -fsSL https://pgp.mongodb.com/server-7.0.asc |  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
# echo "deb [ arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
# sudo apt-get update
# sudo apt-get install -y mongodb-org
# mongod --version

# sudo systemctl status mongod

# Create an MySQL Instance
echo "Installing MySQL"
sudo apt-get install -y mysql-server

sudo systemctl status mysql-server

# # Create a Plex Instance
# curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plexserver.gpg > /dev/null
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/plexserver.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
# sudo apt-get update
# sudo apt-get install -y plexmediaserver
# sudo systemctl status plexmediaserver
# sudo systemctl enable --now plexmediaserver

# Install FreeRadius Server
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential libssl-dev libpam0g-dev libtool autoconf

sudo apt-get install -y freeradius

# mongodb installed from www.mongodb.org 

sudo apt update
sudo apt install --yes gnupg wget haveged

# unifi repository

wget -qO- https://dl.ui.com/unifi/unifi-repo.gpg \
| sudo tee /usr/share/keyrings/unifi-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/unifi-archive-keyring.gpg] \
https://www.ui.com/downloads/unifi/debian stable ubiquiti" \
| sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list > /dev/null

# mongodb-org repository

wget -qO- https://www.mongodb.org/static/pgp/server-3.6.asc \
| sudo gpg --dearmor -o /usr/share/keyrings/mongodb-org-server-3.6-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-org-server-3.6-archive-keyring.gpg] \
https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/3.6 multiverse" \
| sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list > /dev/null

# set JAVA_HOME environment variable for the unifi service

sudo mkdir /etc/systemd/system/unifi.service.d

printf "[Service]\nEnvironment=\"JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\"\n" \
| sudo tee /etc/systemd/system/unifi.service.d/10-override.conf > /dev/null

# Install openjdk 11

sudo apt update
sudo apt install --yes openjdk-11-jre-headless

# Workaround issue where jsvc expects to find libjvm.so at lib/amd64/server/libjvm.so
sudo ln -s /usr/lib/jvm/java-11-openjdk-amd64/lib/ /usr/lib/jvm/java-11-openjdk-amd64/lib/amd64

# Install and enable mongodb 3.6

sudo apt install --yes mongodb-org-server

sudo systemctl enable mongod.service
sudo systemctl start mongod.service

# Install unifi

sudo apt install --yes unifi
sudo apt clean

# Post installation checks

systemctl status --no-pager --full mongod.service unifi.service

wget --no-check-certificate -qO- https://localhost:8443/status | python3 -m json.tool

sudo journalctl --no-pager --unit unifi.service

sudo cat /usr/lib/unifi/logs/server.log

sudo cat /usr/lib/unifi/logs/mongod.log

# Install OMZ
# sudo apt-get install -y zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# sudo omz update

echo END
