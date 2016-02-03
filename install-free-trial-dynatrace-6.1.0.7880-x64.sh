#!/bin/bash

# Issue Free Trial web request
# original request:


curl -H "Content-Type: application/json" -d '{"email":"'"${6}"'","firstName":"'"${4}"'","lastName":"'"${5}"'","company":"'"${7}"'", "sourceTag":"CenturyLink"}' https://eservices.compuwareapm.com/eservices/rest/trialwebservice/processtrialpost

#Install Updates
#apt-get -y update
#yum -y update

#Installing Java if it's not there

# Dynatrace currently does not recommend OpenJDK
#RHEL
# yum -y install java
#Ubuntu
#apt-get install -y default-jre
#apt-get install -y default-jdk
yum install -y wget

# Installing Java JDK
rpm -i jdk-7u71-linux-x64.rpm


#Download DynaTrace
cd /tmp
wget https://s3.amazonaws.com/dtpocdownload/dynatrace-6.1.0.7880-linux-x64.jar -O /tmp/dynatrace-6.1.0.7880-linux-x64.jar

#Build Answerfile
echo "N" >> /tmp/dynatrace_install_answers
echo ${1} >> /tmp/dynatrace_install_answers
echo "Y" >> /tmp/dynatrace_install_answers

#Install DynaTrace
java -jar /tmp/dynatrace-6.1.0.7880-linux-x64.jar < /tmp/dynatrace_install_answers

# Move start scripts and add to proper runlevels

cd ${1}
cp ./init.d/dynaTraceFrontendServer /etc/init.d/dynaTraceFrontendServer
cp ./init.d/dynaTraceBackendServer /etc/init.d/dynaTraceBackendServer
cp ./init.d/dynaTraceCollector /etc/init.d/dynaTraceCollector
chkconfig dynaTraceBackendServer on
chkconfig dynaTraceFrontendServer on
chkconfig dynaTraceCollector on

# install Postgres 9.3 yum repo
yum install -y http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
# install Postgres 9.3 and dependencies
yum install -y postgresql93-server postgresql93-contrib
# initialize Postgres db
service postgresql-9.3 initdb
# make Postgres start on machine boot
chkconfig postgresql-9.3 on

# start Postgres
service postgresql-9.3 start

# secure postgres account and add Dynatrace database and user
echo "ALTER USER postgres WITH PASSWORD '${2}';" > /tmp/dtpgsetup.sql
echo "CREATE USER dynatrace SUPERUSER;" >> /tmp/dtpgsetup.sql
echo "ALTER USER dynatrace WITH PASSWORD '${3}';" >> /tmp/dtpgsetup.sql
echo "CREATE DATABASE dynatrace WITH OWNER dynatrace;" >> /tmp/dtpgsetup.sql

su - postgres -c 'psql -U postgres -f /tmp/dtpgsetup.sql'

# stop service before altering config
service postgresql-9.3 stop
# alter config to use password authentication rather than ident
sed -i 's/ident/md5/' /var/lib/pgsql/9.3/data/pg_hba.conf

# start service
service postgresql-9.3 start

#Start Dynatrace Server Processes

service dynaTraceBackendServer start
service dynaTraceFrontendServer start
service dynaTraceCollector start

# cleanup

rm -f /tmp/dtpgsetup.sql
rm -f /tmp/dynatrace_install_answers
rm -f /tmp/jdk-7u71-linux-x64.rpm
rm -f /tmp/dynatrace-6.1.0.7880-linux-x64.jar


