#!/bin/bash
arguments="$*"
#echo "arguments : $arguments"

#source "$rootDir/bash/scripts/predix_services_setup.sh"

set -e

# Reset all variables that might be set
RUN_EDGE_APP_LOCAL=0
RUN_DEPLOY_TO_EDGE=0

source "$rootDir/bash/scripts/build-basic-app-readargs.sh"


function processReadargs() {
	#process all the switches as normal
	while :; do
			doShift=0
			processEdgeDeployReadargsSwitch $@
			if [[ $doShift == 2 ]]; then
				shift
				shift
			fi
			if [[ $doShift == 1 ]]; then
				shift
			fi
			if [[ $@ == "" ]]; then
				break;
			else
	  			shift
			fi
			#echo "processReadargs $@"
	done
	#echo "Switches=${SWITCH_DESC_ARRAY[*]}"

	printEdgeStarterVariables
}

function processEdgeDeployReadargsSwitch() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	#echo "here$@"
	case $1 in
		-run-edge-app|--run-edge-app)
			RUN_EDGE_APP_LOCAL=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-run-edge-app|--run-edge-app"
			SWITCH_ARRAY[SWITCH_INDEX++]="-run-edge-app"
			PRINT_USAGE=0
			;;
		-deploy-edge-app|--deploy-edge-app)
			RUN_DEPLOY_TO_EDGE=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-deploy-edge-app|--deploy-edge-app"
			SWITCH_ARRAY[SWITCH_INDEX++]="-deploy-edge-app"
			PRINT_USAGE=0
			;;
		-create-packages|--create-packages)
			RUN_CREATE_PACKAGES=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-create-packages|--create-packages"
			SWITCH_ARRAY[SWITCH_INDEX++]="-create-packages"
			PRINT_USAGE=0
			;;
		-repo-name|--repo-name)
			REPO_NAME="$2"
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-repo-name|--repo-name"
			SWITCH_ARRAY[SWITCH_INDEX++]="-repo-name"
			PRINT_USAGE=0
			;;
		-app-name|--app-name)
			APP_NAME="$2"
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-app-name|--app-name"
			SWITCH_ARRAY[SWITCH_INDEX++]="-app-name"
			PRINT_USAGE=0
			;;
		-check-docker-login)
			CHECK_DOCKER_LOGIN=1
			DTR_NAME="$2"
			PRINT_USAGE=0
			;;
		-?*)
			doShift=0
			SUPPRESS_PRINT_UNKNOWN=1
			UNKNOWN_SWITCH=0
			processBuildBasicAppReadargsSwitch $@
			if [[ $UNKNOWN_SWITCH == 1 ]]; then
				echo "unknown Edge Manager switch=$1"
			fi
      ;;
		*)               # Default case: If no more options then break out of the loop.
			;;
  esac
	if [[ -z $DTR_NAME ]]; then
		DTR_NAME="dtr.predix.io"
	fi
}


function printEdgeStarterVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "1" ]]; then
		printBBAVariables
	fi
	echo "EDGE STARTER APP:"
	echo "  RUN_EDGE_APP_LOCAL  : $RUN_EDGE_APP_LOCAL"
	echo "  RUN_DEPLOY_TO_EDGE  : $RUN_DEPLOY_TO_EDGE"
	echo "      "
	export RUN_EDGE_APP_LOCAL
	export RUN_DEPLOY_TO_EDGE
	export REPO_NAME
	export CHECK_DOCKER_LOGIN
	export DTR_NAME
}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-es |      --edge-starter]          => Setup hello world for edge starter"

}

#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionsForEdgeStarter() {
	while :; do
			SUPPRESS_PRINT_UNKNOWN=1
			runFunctionsForBasicApp $1 $2
	    case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-run-edge-app|--run-edge-app)
	          #checkDockerLogin $DTR_NAME
						#if [[ $DOCKER_LOGGED_IN == 0 ]]; then
						#	dockerLogin $DTR_NAME
						#fi
						#checkDockerLogin $DTR_NAME
	          #if [[ $DOCKER_LOGGED_IN == 1 ]]; then
	            runEdgeStarterLocal
	          #fi
	          break
	          ;;
	        -create-packages|--create-packages)
	          echo "Creating Packages"
	          createPackages $APP_NAME
	          break
	          ;;
	        -deploy-edge-app|--deploy-edge-app)
	          echo "deployToEdge"
	          deployToEdge $APP_NAME
	          break
						;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
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
    for image in $(grep "image:" docker-compose-edge-broker.yml | awk -F" " '{print $2}' | tr -d "\"");
    do
      echo "image=$image"
      if [[ $image == dtr.predix.io* ]]; then
      	pullDockerImageFromArtifactory "predix-edge-broker"
      else
        docker pull $image
      fi
    done
    docker service ls -f "name=predix-edge-broker_predix-edge-broker"
    echo "docker stack deploy --with-registry-auth --compose-file docker-compose-edge-broker.yml predix-edge-broker"
    docker stack deploy --with-registry-auth --compose-file docker-compose-edge-broker.yml predix-edge-broker
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
      echo "docker stack deploy --with-registry-auth --compose-file docker-compose-edge-broker.yml predix-edge-broker"  >> $SUMMARY_TEXTFILE
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

    i=0
    for service in $(yq r -j docker-compose-local.yml | jq .services | jq 'keys' | jq '.[]' | tr -d "\"");
    do
      echo "$service";
      ((i++))
      if [[ $service == dtr.predix.io* ]]; then
        pullDockerImageFromArtifactory "$service"
      else
      	j=0
        for image in $(grep "image:" docker-compose-local.yml | awk -F" " '{print $2}' | tr -d "\"");
      	do
	  ((j++))
	  if [[ $j -eq $i ]]; then
	    count=$(docker images "$image" -q | wc -l | tr -d " ")
            echo "count $count"
            if [[ $count == 0 ]]; then
	      echo "docker pull $image"
	      if [[ $(docker pull $image) ]]; then
	        echo "$image downloaded successfully"
	        echo "$image downloaded successfully" >> $SUMMARY_TEXTFILE
	      else
	        echo "$image not downloaded"
	      fi
	    fi
	  fi
	done
      fi
   done

    echo "docker stack deploy --compose-file docker-compose-local.yml $APP_NAME"
    docker stack deploy --compose-file docker-compose-local.yml $APP_NAME
    echo "sleep for 60 seconds"
    sleep 60
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
	export LOGIN_USER

	read -p "Enter your user password> " -s DTR_LOGIN_PASSWORD
	export LOGIN_PASSWORD

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
  read -p "Enter the IP Address of Edge OS($DEFAULT_IP_ADDRESS)> " IP_ADDRESS
  IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_IP_ADDRESS}
  export IP_ADDRESS
  DEFAULT_IP_ADDRESS=$IP_ADDRESS
  declare -p DEFAULT_IP_ADDRESS > .environ
  if [[ ! -n $LOGIN_USER ]]; then
    read -p "Enter the username for Edge OS(root)> " LOGIN_USER
    LOGIN_USER=${LOGIN_USER:-root}
    export LOGIN_USER
  fi
  if [[ ! -n $LOGIN_PASSWORD ]]; then
    read -p "Enter your user password(root)> " -s LOGIN_PASSWORD
    LOGIN_PASSWORD=${LOGIN_PASSWORD:-root}
    export LOGIN_PASSWORD
    echo Login=$LOGIN_PASSWORD
  fi
  expect -c "
    spawn scp -o \"StrictHostKeyChecking=no\" $APP_NAME_TAR $APP_NAME_CONFIG predix-services.tar.gz  $rootDir/bash/scripts/edge-starter-deploy-run.sh $REPO_NAME/data/access_token $LOGIN_USER@$IP_ADDRESS:/mnt/data/downloads
    set timeout 50
    expect {
      \"Are you sure you want to continue connecting\" {
        send \"yes\r\"
        expect \"assword:\"
        send "$LOGIN_PASSWORD\r"
      }
      \"assword:\" {
        send \"$LOGIN_PASSWORD\r\"
      }
    }
    expect \"*# \"
    spawn ssh -o \"StrictHostKeyChecking=no\" $LOGIN_USER@$IP_ADDRESS
    set timeout 5
    expect {
      \"Are you sure you want to continue connecting\" {
        send \"yes\r\"
        expect \"assword:\"
        send \"$LOGIN_PASSWORD\r\"
      }
      "assword:" {
        send \"$LOGIN_PASSWORD\r\"
      }
    }
    set timeout 60
    expect \"*# \"
    send \"su eauser /mnt/data/downloads/edge-starter-deploy-run.sh $APP_NAME \r\"
    expect {
    	\"*# \" { send \"exit\r\" }
	timeout { puts \"timed out during edge-starter-deploy-run.sh\"; exit 1 }
    }
    expect eof
    puts \$expect_out(buffer)

    lassign [wait] pid spawnid os_error_flag value
    if {\$os_error_flag == 0} {
      puts \"exit status: $value\"
    } else {
      puts \"errno: $value\"
    }
  "
  echo "Copied files to $LOGIN_USER@$IP_ADDRESS:/mnt/data/downloads"  >> $SUMMARY_TEXTFILE
  echo "Ran /mnt/data/downloads/edge-starter-deploy-run.sh"  >> $SUMMARY_TEXTFILE
  echo "Launched $REPO_NAME"  >> $SUMMARY_TEXTFILE

  echo "deployToEdge function complete"
}

function pullDockerImageFromArtifactory() {
	dockerImageKey="$1"
  getRepoURL $dockerImageKey dockerImageURL version.json

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
