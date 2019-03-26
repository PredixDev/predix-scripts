#!/bin/bash
set -e

source "$rootDir/bash/scripts/artifactory-functions.sh"

# Using artifactory-functions.sh instead of local-setup-funcs.sh for getCurlArtifactory2
#LOCAL_SETUP_FUNCTIONS="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/local-setup-funcs.sh"
#eval "$(curl -s -L $LOCAL_SETUP_FUNCTIONS)"

EDGE_APP_NAME="predix-edge-broker"
#get the script that reads version.json
dockerImageURL="https://artifactory.predix.io/artifactory/PREDIX-EXT/predix-edge/2_2_0/os/predix-edge-broker-amd64-20181120-1.1.0.signed.tar.gz"
imageTarFile=$(echo "$dockerImageURL" | awk -F"/" '{print $NF}')
mkdir -p temp
cd temp
tar xvfz ../$imageTarFile
docker load -i images.tar
if [[ -e docker-compose.yml ]]; then
  if [[ $(docker network ls -f 'NAME=predix-edge-broker_net' -q | wc -l | tr -d " ") == 0 ]]; then
    docker network create predix-edge-broker_net -d overlay --scope swarm
  fi
  docker stack deploy -c docker-compose.yml $EDGE_APP_NAME
fi

cd ..
rm -rf temp
