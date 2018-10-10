#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Parsing Function
get_config_value()
{
    cat <<EOF | python
import ConfigParser
config = ConfigParser.ConfigParser()
config.read('$1')
print (config.get('$2','$3'))
EOF
}


# MySQL
MYSQL_HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
MYSQL_PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)



Provider="Amazon"

Cloud_keystone_IP=$(get_config_value ../configuration/init.ini provider OpenStack_keystone)

# OpenStack ID & Password ( for tenant == demo )
ID=$(get_config_value ../configuration/init.ini provider OpenStack_ID)
Password=$(get_config_value ../configuration/init.ini provider OpenStack_Password)


Num="3"


operator_host=$(get_config_value ../configuration/init.ini operator Operator_HOST)
operator_id=$(get_config_value ../configuration/init.ini operator Operator_ID)
operator_pass=$(get_config_value ../configuration/init.ini operator Operator_PASS)



# Create OverCloud ID
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="15"

while [ "${n:=1}" -le "$LENGTH" ]
do
    OverCloud_ID="$OverCloud_ID${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    let n+=1
done
echo $OverCloud_ID


# found ID from mysql database
sql=$(mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; select * from tenant where tenant_ID='$ID';")

if [ "$sql" == "" ]; then
  echo "No result"
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into tenant value('$ID');"
else
  echo "Found"
fi


# create tuple for OverCLoud ID
mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into overcloud values('$OverCloud_ID', '$ID');"


# create input.json file
touch input.json
echo '{"operator_host":"'$operator_host'","operator_id":"'$operator_id'","operator_pass":"'$operator_pass'","id":"'$OverCloud_ID'","flavor":"'$Flavor'","number":"'$Num'","provider":"'$Provider'"}' > input.json


# create task_name file
touch task_name.json
echo '{"task_name":"datalake_provisioning"}' > task_name.json


# run mistral execution-create
mistral execution-create Amazon_Instantiation input.json task_name.json

rm input.json
rm task_name.json




