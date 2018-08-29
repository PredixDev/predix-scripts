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

DOCKER_LOGGED_IN=0
if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"
SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
# ********************************** MAIN **********************************
__validate_num_arguments 1 $# "\"$0\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

__append_new_head_log "Deplopy Edge Manager applications to Edge OS" "#" "$logDir"

#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function main() {
  echo "Deploy script"
  if [[ $RUN_EDGE_APP_LOCAL == 1 ]]; then
    checkDockerLogin $DTR_NAME
    if [[ $DOCKER_LOGGED_IN == 1 ]]; then
      echo "runEdgeStarterLocal"
      runEdgeStarterLocal
    fi
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
  #Start local service
  cd `pwd`/$REPO_NAME
  pwd
  if [[ -e docker-compose-edge-broker.yml ]]; then
    for image in $(grep "image:" docker-compose-edge-broker.yml | awk -F" " '{print $2}' | tr -d "\"");
    do
      docker pull $image
    done
    docker service ls -f "name=predix-edge-broker_predix-edge-broker"
    docker stack deploy --with-registry-auth --compose-file docker-compose-edge-broker.yml predix-edge-broker
    if [[  $(docker service ls -f "name=predix-edge-broker" | grep 0/1 | wc -l) == "1" ]]; then
      docker service ls
      echo 'Error: One of the predix-edge-broker services did not launch'
      exit 1
    else
      echo "Deployed following images as docker services"
      for image in $(grep "image:" docker-compose-edge-broker.yml | awk -F" " '{print $2}' | tr -d "\"");
      do
        echo "  $image"
      done
    fi
  else
    echo "docker-compose-edge-broker.yml not found"
  fi
  sleep 5
  echo "runEdgeStarterLocal 111"
  docker images
  if [[ -e docker-compose-local.yml ]]; then
    if [[ -e config/config-cloud-gateway.json ]]; then
      if [[ "$TIMESERIES_INGEST_URI" == "" ]]; then
        getTimeseriesIngestUriFromInstance $TIMESERIES_INSTANCE_NAME
      fi
      if [[ "$TIMESERIES_QUERY_URI" == "" ]]; then
        getTimeseriesQueryUriFromInstance $TIMESERIES_INSTANCE_NAME
      fi
      if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
        getTimeseriesZoneIdFromInstance $TIMESERIES_INSTANCE_NAME
      fi
      if [[ "$UAA_URL" == "" ]]; then
        getTrustedIssuerIdFromInstance $UAA_INSTANCE_NAME
      fi
      echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
      __find_and_replace ".*predix_zone_id\":.*" "          \"predix_zone_id\": \"$TIMESERIES_ZONE_ID\"," "config/config-cloud-gateway.json" "$quickstartLogDir"
      echo "proxy_url : $http_proxy"
      __find_and_replace ".*proxy_url\":.*" "          \"proxy_url\": \"$http_proxy\"" "config/config-cloud-gateway.json" "$quickstartLogDir"

      ./scripts/get-access-token.sh $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $TRUSTED_ISSUER_ID
      cat data/access_token
    fi
    for image in $(grep "image:" docker-compose-local.yml | awk -F" " '{print $2}' | tr -d "\"");
    do
      echo "$image : $APP_NAME"
      if [[ "$image" != "$APP_NAME:latest" ]]; then
        count=$(docker images "$image" -q | wc -l | tr -d " ")
        echo "count $count"
        if [[ $count == 0 ]]; then
          docker pull $image
        fi
      fi

    done
    if [[ -e docker-compose-local.yml ]]; then
      docker build -t $APP_NAME:latest . --build-arg http_proxy --build-arg https_proxy
      docker stack deploy --compose-file docker-compose-local.yml $APP_NAME
      if [[  $(docker service ls -f "name=$APP_NAME" | grep 0/1 | wc -l) == "1" ]]; then
        docker service ls
        echo 'Error: One of the $APP_NAME services did not launch'
        exit 1
      fi
    fi
    echo "runEdgeStarterLocal 333"
    docker images
  else
    echo "docker-compose-local.yml not found"
  fi
  docker images
}

function checkDockerLogin {
  DOCKER_CONFIG="~/.docker/config.json"
  DTR_NAME="$1"
  #echo "DTR_NAME : $DTR_NAME"
  loggedIn=$(jq -r ".auths | .[\"$DTR_NAME\"]?" ~/.docker/config.json)
  #echo "Logged in? $loggedIn"
  if [[ -z $loggedIn ]]; then
    echo "Not Logged in"
  else
    echo "Docker logged in"
  fi
  DOCKER_LOGGED_IN=1
  if [[ ! $(docker swarm init) ]]; then
    echo "Already in swarm node. Ignore the above error message"
  fi
}

function createPackages {
  echo "1111"
  cd $REPO_NAME
  pwd
  echo "Deploying $APP_NAME"
  APP_NAME_TAR="$APP_NAME.tar.gz"
  echo "RECREATE_TAR : $RECREATE_TAR"
  ls
  if [[ "$RECREATE_TAR" == "1" || ! -e "images.tar" ]]; then
    echo "Creating a images.tar with required images"
    rm -rf images.tar
    IMAGES_LIST=""
    for img in $(cat docker-compose.yml | grep image: | awk -F" " '{print $2}' | tr -d "\"");
    do
      IMAGES_LIST="$IMAGES_LIST $img"
    done
    echo "$IMAGES_LIST"
    docker save -o images.tar $IMAGES_LIST
  fi
  if [[ "$RECREATE_TAR" == "1" || ! -e "$APP_NAME_TAR" ]]; then
    rm -rf "$APP_NAME_TAR"
    echo "Creating $APP_NAME_TAR with docker-compose.yml"
    tar -czvf $APP_NAME_TAR images.tar docker-compose.yml
  fi

  APP_NAME_CONFIG="$APP_NAME-config.zip"

  if [[ -e config ]]; then
    if [[ "$RECREATE_TAR" == "1" || ! -e "$APP_NAME_CONFIG" ]]; then
      rm -rf $APP_NAME_CONFIG
      echo "Compressing the configurations."
      cd config
      zip -X -r ../$APP_NAME_CONFIG *.json
      cd ../
    fi
  fi
  ls -lrt
}
function deployToEdge {
  if [[ ! -n $IP_ADDRESS ]]; then
    read -p "Enter the IP Address of Edge OS> " IP_ADDRESS
    export IP_ADDRESS
  fi
  if [[ ! -n $LOGIN_USER ]]; then
    read -p "Enter the username for Edge OS> " LOGIN_USER
    export LOGIN_USER
  fi
  if [[ ! -n $LOGIN_PASSWORD ]]; then
    read -p "Enter your user password> " -s LOGIN_PASSWORD
    export LOGIN_PASSWORD
  fi

  pwd
  expect -c "
    spawn scp -o \"StrictHostKeyChecking=no\" $APP_NAME_TAR $APP_NAME_CONFIG predix-services.tar.gz $rootDir/bash/scripts/edge-starter-deploy-run.sh $LOGIN_USER@$IP_ADDRESS:/mnt/data/downloads
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
    expect \"*\# \"
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
    expect \"*\# \"
    send \"su eauser /mnt/data/downloads/edge-starter-deploy-run.sh $APP_NAME\r\"
    set timeout 20
    expect \"*\# \"
    send \"exit\r\"
    expect eof
  "

  sleep 20
  # Automagically open the application in browser, based on OS
  if [[ $SKIP_BROWSER == 0 ]]; then
    app_url="http://$IP_ADDRESS:9098"

    case "$(uname -s)" in
       Darwin)
         # OSX
         open $app_url
         ;;
       Linux)
         # OSX
         xdg-open $app_url
         ;;
       CYGWIN*|MINGW32*|MINGW64*|MSYS*)
         # Windows
         start "" $app_url
         ;;
    esac
  fi
}
