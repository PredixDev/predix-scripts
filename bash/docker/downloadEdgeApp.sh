#!/bin/bash
set -e

EDGE_APP_NAME="$2"
#get the script that reads version.json
LOCAL_SETUP_FUNCTIONS="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/local-setup-funcs.sh"
dockerImageURL="$1"
imageTarFile=$(echo "$dockerImageURL" | awk -F"/" '{print $NF}')
eval "$(curl -s -L $LOCAL_SETUP_FUNCTIONS)"
getCurlArtifactory $dockerImageURL
mkdir -p temp
cd temp
tar xvfz ../$imageTarFile
docker load -i images.tar
cd ..
rm -rf temp
