#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to instal application specific repos,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

trap "trap_ctrlc" 2

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

EDGE_STARTER_IMAGE_MQTT="dtr.predix.io/predix-edge/predix-edge-mosquitto-amd64"
EDGE_STARTER_IMAGE_REDIS="registry.gear.ge.com/predix_edge/redis-amd64"
EDGE_STARTER_IMAGE_WIND_WORK_BENCH="registry.gear.ge.com/predix_edge/wind-workbench:0.1"

EDGE_STARTER_INSTANCE_NAME_REDIS="edgeservices_cdp_redis"
EDGE_STARTER_INSTANCE_NAME_MQTT="edgeservices_cdp_mqtt"
EDGE_STARTER_INSTANCE_NAME_WIND_WORKBENCH="edge-hello-world"
#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function edge-starter-hello-world-main() {
  __append_new_head_log "Build & Deploy Edge starter Hello world" "#" "$logDir"

  __append_new_line_log "Download and start redis" "$logDir"
  stop_container=$(docker container ls -a | grep "$EDGE_STARTER_INSTANCE_NAME_REDIS" | awk -F" " '{print $1}')
  docker stop $stop_container && docker rm $stop_container
  __append_new_line_log "Stopped : $EDGE_STARTER_INSTANCE_NAME_REDIS" "$logDir"
  echo "docker run -d -p \"6379:6379\" --name $EDGE_STARTER_INSTANCE_NAME_REDIS $EDGE_STARTER_IMAGE_REDIS:latest redis-server"
  docker run -d -p "6379:6379" --name $EDGE_STARTER_INSTANCE_NAME_REDIS $EDGE_STARTER_IMAGE_REDIS:latest redis-server
  __append_new_line_log "Started : $EDGE_STARTER_INSTANCE_NAME_REDIS" "$logDir"

  __append_new_line_log "Download and start edge broker" "$logDir"
  stop_container=$(docker container ls -a | grep "$EDGE_STARTER_INSTANCE_NAME_MQTT" | awk -F" " '{print $1}')
  docker stop $stop_container && docker rm $stop_container
  __append_new_line_log "Stopped : $EDGE_STARTER_INSTANCE_NAME_MQTT" "$logDir"
  echo "docker run -d -p \"1883:1883\" -p \"9001:9001\" --name $EDGE_STARTER_INSTANCE_NAME_MQTT $EDGE_STARTER_IMAGE_MQTT:latest"
  docker run -d -p "1883:1883" -p "9001:9001" --name $EDGE_STARTER_INSTANCE_NAME_MQTT $EDGE_STARTER_IMAGE_MQTT:latest
  __append_new_line_log "Started : $EDGE_STARTER_INSTANCE_NAME_MQTT" "$logDir"
  sleep 10
  export UPDATE_RATE_SEC=1.0
  export TURBINE_IN_CHANNEL=turbine_control
  export TURBINE_OUT_CHANNEL=turbine_measurement
  export WEATHER_OUT_CHANNEL=weather
  __append_new_line_log "Download and start wind workbench" "$logDir"
  stop_container=$(docker container ls -a | grep "$EDGE_STARTER_INSTANCE_NAME_WIND_WORKBENCH" | awk -F" " '{print $1}')
  docker stop $stop_container && docker rm $stop_container
  __append_new_line_log "Stopped : $EDGE_STARTER_INSTANCE_NAME_WIND_WORKBENCH" "$logDir"
  echo "docker run -d -p \"9098:9005\" --name $EDGE_STARTER_INSTANCE_NAME_WIND_WORKBENCH -e UPDATE_RATE_SEC -e TURBINE_IN_CHANNEL -e TURBINE_OUT_CHANNEL -e WEATHER_OUT_CHANNEL --link $EDGE_STARTER_INSTANCE_NAME_REDIS:$EDGE_STARTER_INSTANCE_NAME_REDIS --link $EDGE_STARTER_INSTANCE_NAME_MQTT:$EDGE_STARTER_INSTANCE_NAME_MQTT $EDGE_STARTER_IMAGE_WIND_WORK_BENCH"
  docker run -d -p "9098:9005" --name $EDGE_STARTER_INSTANCE_NAME_WIND_WORKBENCH -e UPDATE_RATE_SEC -e TURBINE_IN_CHANNEL -e TURBINE_OUT_CHANNEL -e WEATHER_OUT_CHANNEL --link $EDGE_STARTER_INSTANCE_NAME_REDIS:$EDGE_STARTER_INSTANCE_NAME_REDIS --link $EDGE_STARTER_INSTANCE_NAME_MQTT:$EDGE_STARTER_INSTANCE_NAME_MQTT $EDGE_STARTER_IMAGE_WIND_WORK_BENCH
  sleep 10
  open http://127.0.0.1:9098/

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Edge starter Hello world"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Downloaded and Started docker containers for Redis, MQTT and Wind Workbench"  >> $SUMMARY_TEXTFILE
  echo "App URL: http://127.0.0.1:9098" >> $SUMMARY_TEXTFILE
}
