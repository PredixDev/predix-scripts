#!/bin/bash
set -e
source "$rootDir/bash/scripts/artifactory-functions.sh"

function checkDockerLogin {
  DOCKER_CONFIG="$HOME/.docker/config.json"
  echo "DOCKER_CONFIG=$DOCKER_CONFIG"
  DTR_NAME="$1"
  if [[ -e $DOCKER_CONFIG ]]; then
    #echo "DTR_NAME : $DTR_NAME"
    loggedIn=$(jq -r ".auths | .[\"$DTR_NAME\"]?" ~/.docker/config.json)
    echo "Logged in? $loggedIn"
    if [[ $(jq -r ".auths | .[\"$DTR_NAME\"]?" ~/.docker/config.json) != null ]]; then
      echo "Docker logged in"
      DOCKER_LOGGED_IN=1
   else
     DOCKER_LOGGED_IN=0
     echo "Not Logged in"
   fi
  else
	DOCKER_LOGGED_IN=0
	echo "Not Logged in"
  fi
}

function dockerLogin {
	DTR_NAME="$1"

	read -p "Enter the username for dtr $DTR_NAME> " DTR_LOGIN_USER
	export DTR_LOGIN_USER

	read -p "Enter your user password> " -s DTR_LOGIN_PASSWORD
	export DTR_LOGIN_PASSWORD

	if [[ $(docker login $DTR_NAME -u $DTR_LOGIN_USER -p $DTR_LOGIN_PASSWORD) ]]; then
		echo "Docker login successful"
	else
		echo "Docker login failed"
		exit 1
	fi
}

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
    getCurlArtifactory2 $dockerImageURL
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

function updateConfigAndToken {
  __append_new_head_log "Update Configs and Token" "-" "$quickstartLogDir"
  cd $REPO_NAME
  if [[ -e config/config-cloud-gateway.json ]]; then
    if [[ "$SKIP_PREDIX_SERVICES" == "false" ]]; then
			if [[ "$TIMESERIES_QUERY_URI" == "" ]]; then
				getTimeseriesQueryUriFromInstance $TIMESERIES_INSTANCE_NAME
			fi
			if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
				getTimeseriesZoneIdFromInstance $TIMESERIES_INSTANCE_NAME
			fi
			if [[ "$TRUSTED_ISSUER_ID" == "" ]]; then
				getTrustedIssuerIdFromInstance $UAA_INSTANCE_NAME
			fi
			echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
			echo "TRUSTED_ISSUER_ID : $TRUSTED_ISSUER_ID"
			if [[ -e config/config-cloud-gateway.json ]]; then
			  __find_and_replace ".*predix_zone_id\":.*" "          \"predix_zone_id\": \"$TIMESERIES_ZONE_ID\"," "config/config-cloud-gateway.json" "$quickstartLogDir"
			  echo "proxy_url : $http_proxy"
			  __find_and_replace ".*proxy_url\":.*" "          \"proxy_url\": \"$http_proxy\"" "config/config-cloud-gateway.json" "$quickstartLogDir"
			fi
			if [[ -e docker-compose-local.yml ]]; then
		      	  echo "proxy_url : $http_proxy"
		      	  __find_and_replace ".*http_proxy:.*" "      http_proxy: \"$http_proxy\"" "docker-compose-local.yml" "$quickstartLogDir"
			fi
			#./scripts/get-access-token.sh $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $TRUSTED_ISSUER_ID
			createAccessTokenFile $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $TRUSTED_ISSUER_ID
			cat data/access_token
    else
    	echo "SKIP_PREDIX_SERVICES=$SKIP_PREDIX_SERVICES so will not update proxy and cloud config file variables"
    fi
  fi
  cd ..
}

function createPackages {
  __append_new_head_log "Create Packages for $APP_NAME" "-" "$quickstartLogDir"
  APP_NAME_TAR="$APP_NAME.tar.gz"
  if [[ -e $APP_NAME_TAR ]]; then
    echo "$APP_NAME_TAR exists"
    return
  fi
  updateConfigAndToken

  echo "RECREATE_TAR : $RECREATE_TAR"
  if [[ "$RECREATE_TAR" == "1" || ! -e "images.tar" ]]; then
    echo "Creating a images.tar with required images"
    rm -rf images.tar
    IMAGES_LIST=""
    for img in $(cat $REPO_NAME/docker-compose.yml | grep image: | awk -F" " '{print $2}' | tr -d "\"");
    do
      IMAGES_LIST="$IMAGES_LIST $img"
    done
    echo "$IMAGES_LIST"
    docker save -o images.tar $IMAGES_LIST
  fi
  if [[ "$RECREATE_TAR" == "1" || ! -e "$APP_NAME_TAR" ]]; then
    rm -rf "$APP_NAME_TAR"
    echo "Creating $APP_NAME_TAR with docker-compose.yml"
    cp $REPO_NAME/docker-compose.yml .
    tar -czvf $APP_NAME_TAR images.tar docker-compose.yml
  fi

  APP_NAME_CONFIG="$APP_NAME-config.zip"

  if [[ -e $REPO_NAME/config ]]; then
    if [[ "$RECREATE_TAR" == "1" || ! -e "$APP_NAME_CONFIG" ]]; then
      rm -rf $APP_NAME_CONFIG
      echo "Compressing the configurations."
      cd $REPO_NAME/config
      extensions=''
      #no extensions
      for file in `find . -type f -depth 1 ! -name '*.*' | grep -v '\./\.' | sed 's|\./||' | sort -u`;  do
        echo "file=$file"
        extensions="$extensions $file"
      done
      #files with extensions
      for extension in `find . -type f -depth 1 -name '*.*' | grep -v '\./\.' | sed 's|.*\.||' | sort -u`;  do
        echo "extension=$extension"
        extensions="$extensions *.$extension"
      done
      echo $extensions
      zip -X -r ../$APP_NAME_CONFIG $extensions
      cd ../..
    fi
  fi
  echo "Packaged $APP_NAME_TAR"  >> $SUMMARY_TEXTFILE
  echo "Packaged $APP_NAME_CONFIG"  >> $SUMMARY_TEXTFILE

  echo "Creating Packages for $APP_NAME complete"
}

function createAccessTokenFile(){
	CLIENT_ID=$1
	SECRET=$2
	UAA_URL=$3

	echo "usage: createAccessTokenFile <clientId> <secret> <uaa-issuerid-url>"

  # base64 encide the client and secret
  AUTH='Authorization: Basic '$(echo -n $CLIENT_ID:$SECRET | base64)

  # curl the UAA token url to get an access tojken
  RESULT=$(curl -X POST $UAA_URL  -H "$AUTH" -H 'Content-Type: application/x-www-form-urlencoded' -d grant_type=client_credentials)

  # parse out the access token from the result - this requires jq to be installed on your machine (brew install jq)
  if [[ $( echo "$RESULT" | jq 'has("access_token")') == true ]]; then
    ACCESS_TOKEN=$( echo "$RESULT" | jq -r '.["access_token"]' )
    # copy the access token to the access_token file in the data folder of your app - where the Cloud Gateway container will look for it
    mkdir -p ./data
    printf "%s" "$ACCESS_TOKEN" > ./data/access_token
    chmod -R 777 data
    echo 'token refreshed'
  else
    echo "Coult not fetch token : $RESULT"
    echo "Please check if the paramters passed are correct"
    echo "$CLIENT_ID $SECRET $UAA_URL"
    echo "CURL COMAND : curl -X POST $UAA_URL  -H "$AUTH" -H 'Content-Type: application/x-www-form-urlencoded' -d grant_type=client_credentials"
    mkdir -p ./data
    printf "%s" "" > ./data/access_token
    chmod -R 777 data
    exit 1
  fi
}

function  waitForService() {
  waitTime=$1
  theApp=$2
  counter=1
  echo "Sleeping up to $waitTime seconds"
  while [[ $counter < $waitTime ]]; do
    sleep 5
    if [[  $(docker service ls -f "name=$theApp" | grep 0/1 | wc -l) == "1" ]]; then
      echo "Service $theApp not started. Waiting a litle more time"
      counter=$(( counter + 5 ))
    else
      echo "Service started."
      counter=$(( counter + waitTime ))
    fi
  done
}
