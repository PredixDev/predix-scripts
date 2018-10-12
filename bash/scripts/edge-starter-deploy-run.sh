#!/bin/bash

trap "trap_ctrlc" 2

APPLICATION_ID="$1"
APP_SERVICE_NAME="$APPLICATION_ID_$APPLICATION_ID"
EDGE_APP="$APPLICATION_ID.tar.gz"
EDGE_APP_CONFIG="$APPLICATION_ID-config.zip"

ROOT_DIR=$(pwd)
echo $APP_SERVICE_NAME

count=$(docker service ls --filter name=\'$APPLICATION_ID\' -q | wc -l)
if [[ $count == 0 ]]; then
  echo "No services to delete"
else
  docker service rm $(docker service ls --filter name=\'$APPLICATION_ID\')
fi


#if [[ $(docker service ls -f "name=$APP_SERVICE_NAME" -q | wc -l) -eq 1 ]]; then
#  docker service rm "$APP_SERVICE_NAME"
#  echo "$APPLICATION_ID service removed"
#else
#  echo "$APPLICATION_ID service not found"
#fi


mkdir -p /var/lib/edge-agent/app/$APPLICATION_ID/conf/
rm -rf /var/lib/edge-agent/app/$APPLICATION_ID/conf/*
unzip /mnt/data/downloads/$EDGE_APP_CONFIG -d /var/lib/edge-agent/app/$APPLICATION_ID/conf/
echo "unzip complete"
#/opt/edge-agent/app-start --appInstanceId=$APPLICATION_ID

#if [[ $(curl http://localhost/api/v1/applications --unix-socket /var/run/edge-core/edge-core.sock -X POST -F "file=@/mnt/data/downloads/$EDGE_APP" -H "app_name: $APPLICATION_ID") ]]; then
/opt/edge-agent/app-deploy --enable-core-api $APPLICATION_ID /mnt/data/downloads/$EDGE_APP
echo "deploy complete"
if [[ $(docker service ls -f "name=$APP_SERVICE_NAME" -q | wc -l) > 0 ]]; then
  echo "$APPLICATION_ID service started"
  docker service logs $(docker service ls -f "name=$APP_SERVICE_NAME" -q)
else
  echo "$APPLICATION_ID not service started"
fi
