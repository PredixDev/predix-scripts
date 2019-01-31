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

echo "$*"

# ********************************** MAIN **********************************
__validate_num_arguments 1 $# "\"edge-starter-deploy.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

__append_new_head_log "Build & Deploy Predix Edge Application" "#" "$logDir"

#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function main() {
  if [[ $RUN_EDGE_APP_LOCAL == 1 ]]; then
    echo ""
    runEdgeStarterLocal
  fi
  if [[ $RUN_CREATE_PACKAGES == 1 ]]; then
    echo "Creating Packages"
    createPackages $APP_NAME
  fi
  if [[ $RUN_DEPLOY_TO_EDGE == 1 ]]; then
    echo "deployToEdge"
    deployToEdge $APP_NAME
  fi
}

function runEdgeStarterLocal() {
  __append_new_head_log "Edge Starter Local" "-" "$quickstartLogDir"
  pwd
  updateConfigAndToken
  cd `pwd`/$REPO_NAME
  pwd
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Deployed Edge Application with dependencies"  >> $SUMMARY_TEXTFILE
  if [[ ! $(docker swarm init) ]]; then
        echo "Already in swarm node. Ignore the above error message"
  fi
  if [[ -e docker-compose-edge-broker.yml ]]; then
    __append_new_head_log "Edge Starter Local - Launch Predix Edge Data Broker" "-" "$quickstartLogDir"
    processDockerCompose "docker-compose-edge-broker.yml"
    docker network ls
    echo "docker stack rm $APP_NAME"
    docker stack rm $APP_NAME
    docker stack ls
    docker service ls -f "name=predix-edge-broker_predix-edge-broker"
    if [[  $(docker service ls -f "name=predix-edge-broker" | grep 1/1 | wc -l) == "1" ]]; then
      echo "docker stack rm predix-edge-broker"
      docker stack rm "predix-edge-broker"
    fi
    docker network ls
    echo "docker stack deploy --compose-file docker-compose-edge-broker.yml predix-edge-broker"
    docker stack deploy --compose-file docker-compose-edge-broker.yml predix-edge-broker
    echo "sleep for 30 seconds"
    sleep 30
    if [[  $(docker service ls -f "name=predix-edge-broker" | grep 0/1 | wc -l) == "1" ]]; then
      docker service ls
      echo 'Error: One of the predix-edge-broker services did not launch'
      exit 1
    else
      echo "Deployed following images as docker services"
      echo "Deployed following images as docker services"  >> $SUMMARY_TEXTFILE
      for image in $(grep "image:" docker-compose-edge-broker.yml | awk -F" " '{print $2}' | tr -d "\"");
      do
        echo "  $image"
        echo "  $image" >> $SUMMARY_TEXTFILE
      done
      echo "Launched with"  >> $SUMMARY_TEXTFILE
      echo "docker stack deploy --compose-file docker-compose-edge-broker.yml predix-edge-broker"  >> $SUMMARY_TEXTFILE
    fi
  else
    echo "docker-compose-edge-broker.yml not found"
  fi
  sleep 5
  docker images
  if [[ -e docker-compose-local.yml ]]; then
      __append_new_head_log "Edge Starter Local - Launch App" "-" "$quickstartLogDir"
    if [[ -d "data/store_forward_queue" ]]; then
    	mkdir -p data/store_forward_queue
    fi
    if [[ -e "data" ]]; then
    	chmod -R 777 data
    fi

    processDockerCompose "docker-compose-local.yml"

    echo "docker stack deploy --compose-file docker-compose-local.yml $APP_NAME"
    docker stack rm $APP_NAME
    docker stack deploy --compose-file docker-compose-local.yml $APP_NAME
    echo "sleep for 60 seconds"
    sleep 60
    docker stack ps $APP_NAME
    if [[  $(docker service ls -f "name=$APP_NAME" | grep 0/1 | wc -l) == "1" ]]; then
      docker service ls
      echo 'Error: One of the $APP_NAME services did not launch.  Try re-running again, maybe we did not give it enough time to come up.  See the image github README for troubleshooting details.'
      exit 1
    else
      echo "Launched with"  >> $SUMMARY_TEXTFILE
      echo "docker stack deploy --compose-file docker-compose-local.yml $APP_NAME"  >> $SUMMARY_TEXTFILE
    fi

    echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
    if [[ -e docker-compose-edge-broker.yml ]]; then
    	echo "Downloaded and Deployed the Predix Edge Broker as defined in docker-compose-edge-broker.yml" >> $SUMMARY_TEXTFILE
    	for  image in $(grep "image:" docker-compose-edge-broker.yml | awk -F" " '{print $2}' | tr -d "\"");
    	do
    		echo "	$image" >> $SUMMARY_TEXTFILE
    	done
	     echo "" >> $SUMMARY_TEXTFILE
    fi
    if [[ -e docker-compose-local.yml ]]; then
		  echo "Downloaded and Deployed the Docker images as defined in docker-compose-local.yml" >> $SUMMARY_TEXTFILE
  		for  image in $(grep "image:" docker-compose-local.yml | awk -F" " '{print $2}' | tr -d "\"");
  		do
  			 echo "	$image" >> $SUMMARY_TEXTFILE
  		done
  		echo "" >> $SUMMARY_TEXTFILE
    fi
  	echo -e "You can execute 'docker service ls' to view services deployed" >> $SUMMARY_TEXTFILE
  	echo -e "You can execute 'docker service logs <service id>' to view the logs" >> $SUMMARY_TEXTFILE
	else
      echo "docker-compose-local.yml not found"
  fi
  docker images
  cd ..
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
			./scripts/get-access-token.sh $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $TRUSTED_ISSUER_ID
			cat data/access_token
    else
    	echo "SKIP_PREDIX_SERVICES=$SKIP_PREDIX_SERVICES so will not update proxy and cloud config file variables"
    fi
  fi
  cd ..
}

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
      zip -X -r ../../$APP_NAME_CONFIG *.json
      cd ../..
    fi
  fi
  echo "Packaged $APP_NAME_TAR"  >> $SUMMARY_TEXTFILE
  echo "Packaged $APP_NAME_CONFIG"  >> $SUMMARY_TEXTFILE

  echo "Creating Packages for $APP_NAME complete"
}

function deployToEdge {
  __append_new_head_log "Deploy to Predix Edge OS" "-" "$quickstartLogDir"
  if [[ -e .environ ]]; then
    source .environ
  fi
  read -p "Enter the IP Address of Edge OS($DEFAULT_IP_ADDRESS)> " DEVICE_IP_ADDRESS
  DEVICE_IP_ADDRESS=${DEVICE_IP_ADDRESS:-$DEFAULT_IP_ADDRESS}
  export DEVICE_IP_ADDRESS
  DEFAULT_IP_ADDRESS=$DEVICE_IP_ADDRESS
  declare -p DEFAULT_IP_ADDRESS > .environ
  if [[ ! -n $DEVICE_LOGIN_USER ]]; then
    read -p "Enter the username for Edge OS(root)> " DEVICE_LOGIN_USER
    DEVICE_LOGIN_USER=${DEVICE_LOGIN_USER:-root}
    export DEVICE_LOGIN_USER
  fi
  if [[ ! -n $DEVICE_LOGIN_PASSWORD ]]; then
    read -p "Enter your user password(root)> " -s DEVICE_LOGIN_PASSWORD
    DEVICE_LOGIN_PASSWORD=${DEVICE_LOGIN_PASSWORD:-root}
    export DEVICE_LOGIN_PASSWORD
    echo Login=$DEVICE_LOGIN_PASSWORD
  fi
  if [[ "$SKIP_PREDIX_SERVICES" == "false" ]]; then
    pwd
    cd $REPO_NAME
    if [[ "$TRUSTED_ISSUER_ID" == "" ]]; then
      getTrustedIssuerIdFromInstance $UAA_INSTANCE_NAME
    fi
    ./scripts/get-access-token.sh $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $TRUSTED_ISSUER_ID
    cat data/access_token
    cd ..
  fi
	if [[ $(ssh-keygen -F $DEVICE_IP_ADDRESS | wc -l | tr -d " ") != 0 ]]; then
		ssh-keygen -R $DEVICE_IP_ADDRESS
	fi
  expect -c "
    set timeout -1
		spawn scp -o \"StrictHostKeyChecking=no\" $APP_NAME_TAR $APP_NAME_CONFIG $rootDir/bash/scripts/edge-starter-deploy-run.sh $REPO_NAME/data/access_token $DEVICE_LOGIN_USER@$DEVICE_IP_ADDRESS:/mnt/data/downloads
    expect {
      \"Are you sure you want to continue connecting\" {
        send \"yes\r\"
        expect \"assword:\"
        send "$DEVICE_LOGIN_PASSWORD\r"
      }
      \"assword:\" {
        send \"$LOGIN_PASSWORD\r\"
      }
    }
		set timeout -1
    expect \"*# \"
    spawn ssh -o \"StrictHostKeyChecking=no\" $DEVICE_LOGIN_USER@$DEVICE_IP_ADDRESS
    set timeout -1
    expect {
      \"Are you sure you want to continue connecting\" {
        send \"yes\r\"
        expect \"assword:\"
        send \"$DEVICE_LOGIN_PASSWORD\r\"
      }
      "assword:" {
        send \"$DEVICE_LOGIN_PASSWORD\r\"
      }
    }
    set timeout -1
    expect \"*# \"
    send \"cp /mnt/data/downloads/access_token /var/run/edge-agent/access-token \r\"
    expect \"*# \"
    send \"su eauser /mnt/data/downloads/edge-starter-deploy-run.sh $APP_NAME \r\"
		set timeout -1
		expect {
    	\"*# \" { send \"exit\r\" }
	timeout { puts \"timed out during edge-starter-deploy-run.sh\"; exit 1 }
    }
    expect eof
    puts \"after eof\r\"
    set waitval [wait -i $spawn_id]
    set exval [lindex $waitval 3]
    puts \"exval=$exval\"
    exit $exval

    puts \$expect_out(buffer)
    lassign [wait] pid spawnid os_error_flag value
    if {\$os_error_flag == 0} {
      puts \"exit status: $value\"
    } else {
      puts \"errno: $value\"
    }
  "
  echo "exit code=$?"
  echo "Copied files to $DEVICE_LOGIN_USER@$DEVICE_IP_ADDRESS:/mnt/data/downloads"  >> $SUMMARY_TEXTFILE
  echo "Ran /mnt/data/downloads/edge-starter-deploy-run.sh"  >> $SUMMARY_TEXTFILE
  echo "Launched $REPO_NAME"  >> $SUMMARY_TEXTFILE

  echo "deployToEdge function complete"
}

function pullDockerImageFromArtifactory() {
	dockerImageKey="$1"
  dockerImageURL="$2"

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

function processDockerCompose() {
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
