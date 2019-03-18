#!/bin/bash
set -e

function getRepoURL {
	local  repoURLVar=$2
	reponame=$(echo "$1" | awk -F "/" '{print $NF}')
	echo reponame=$reponame
	url=$( jq -r --arg repo "$reponame" .dependencies[\$repo]  $3 | awk -F"#" '{print $1}')
	echo "url=$url"
	#url=$(echo "$a" | sed -n "/$reponame/p" $rootDir/../../version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $1}')
	eval $repoURLVar="'$url'"
}

#TODO - should this function be in a Docker file not bash_functions.sh?
function pullDockerImageFromArtifactory() {
  echo "Running pullDockerImageFromArtifactory"
  dockerImageKey="$1"
  dockerImageURL="$2"
  LOCAL_SETUP_FUNCTIONS="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/local-setup-funcs.sh"
  eval "$(curl -s -L $LOCAL_SETUP_FUNCTIONS)"
  echo "dockerImageKey : $dockerImageKey"
  echo "dockerImageURL : $dockerImageURL"
  if [[ -z $dockerImageURL || $dockerImageURL == null ]]; then
    echo "$dockerImageKey not present in version.json"
    exit 1
  else
    imageTarFile=$(echo "$dockerImageURL" | awk -F"/" '{print $NF}')
    getCurlArtifactory $dockerImageURL
    mkdir -p temp
    cd temp
    tar xvfz ../$imageTarFile
    docker load -i images.tar
    cd ..
    rm -rf temp
  fi
}

#TODO - should this function be in a Docker file not bash_functions.sh?
function processDockerCompose() {
  echo "Running processDockerCompose"
  dockerComposeFile="$1"
  yq --version
  if [ "$(uname)" == "Linux" ]; then
    services=$(yq . $dockerComposeFile | jq ."services" | jq 'keys' | jq '.[]' | tr -d "\"")
  elif [ "$(uname)" == "Darwin" ]; then
    services=$(yq r -j $dockerComposeFile | jq ."services" | jq 'keys' | jq '.[]' | tr -d "\"")
  else
    echo "unsupported OS $(uname)"
    exit 1
  fi
  for service in $services;
  do
    echo "service $service"
    search=$(echo ".services[\"$service\"].image")
    if [ "$(uname)" == "Linux" ]; then
      image=$(yq . $dockerComposeFile | jq -r $(echo $search))
    elif [ "$(uname)" == "Darwin" ]; then
      image=$(yq r -j $dockerComposeFile | jq -r $(echo $search))
    fi
    echo "image : $image"
    count=$(docker images "$image" -q | wc -l | tr -d " ")
    echo "Count : $count"
    if [[ $count == 0 ]]; then
	echo "Image not present. downloading"
	getRepoURL $service dockerImageURL version.json
	echo "docker tip: if docker pull fails, try adding proxy info to the docker daemon (if behind a proxy)"
	echo "docker tip: if docker pull fails, try 'docker logout' if pulling from public hub.docker.com"
	if [[ $dockerImageURL == *github* ]]; then
	  echo "docker pull $image"
	  docker pull $image
	elif [[ -z $dockerImageURL || $dockerImageURL == null ]]; then
	  echo "docker pull $image"
	  docker pull $image
	else
	  echo "Pulling from artifactory"
	  pullDockerImageFromArtifactory $service $dockerImageURL
	fi
    fi
  done
}
