#!/bin/bash
set -e
source "$rootDir/bash/scripts/artifactory-functions.sh"

# Using artifactory-functions.sh instead of local-setup-funcs.sh for getCurlArtifactory2
#LOCAL_SETUP_FUNCTIONS="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/local-setup-funcs.sh"
#eval "$(curl -s -L $LOCAL_SETUP_FUNCTIONS)"

EDGE_APP_NAME="$2"
#get the script that reads version.json
dockerImageURL="$1"
imageTarFile=$(echo "$dockerImageURL" | awk -F"/" '{print $NF}')
getCurlArtifactory2 $dockerImageURL
mkdir -p temp
cd temp
tar xvfz ../$imageTarFile
docker load -i images.tar
cd ..
rm -rf temp
