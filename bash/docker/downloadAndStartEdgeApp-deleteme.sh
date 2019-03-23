#!/bin/bash
set -e

EDGE_APP_NAME="$2"
#get the script that reads version.json
LOCAL_SETUP_FUNCTIONS="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/local-setup-funcs.sh"
dockerImageURL="$1"
imageTarFile=$(echo "$dockerImageURL" | awk -F"/" '{print $NF}')
eval "$(curl -s -L $LOCAL_SETUP_FUNCTIONS)"
getCurlArtifactory2 $dockerImageURL
mkdir -p temp
cd temp
tar xvfz ../$imageTarFile
docker load -i images.tar
if [[ $(docker network ls -f 'NAME=predix-edge-broker_net' -q | wc -l | tr -d " ") > 0 ]]; then
  docker stack deploy -c docker-compose.yml $EDGE_APP_NAME
else
  echo "predix-edge-broker_net is not found. maybe the current image does not need network."
  echo "However for other docker containers to access this service, you will need to create a network."
  echo "You can create the netowrk as below and re-run $0"
  echo "  docker network create predix-edge-broker_net -d overlay --scope swarm"
fi
cd ..
rm -rf temp
