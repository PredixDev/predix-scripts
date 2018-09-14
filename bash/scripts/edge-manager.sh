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
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

trap "trap_ctrlc" 2

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"
SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
# ********************************** MAIN **********************************
__validate_num_arguments 1 $# "\"edge-manager.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

__append_new_head_log "Create/Manage Edge Manager operations" "#" "$logDir"

#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function main() {
  #execute the build a basic app and switches
  echo "EDGE_APP_NAME : $EDGE_APP_NAME"
  echo "EM_TENANT_TOKEN : $EM_TENANT_TOKEN"
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "EM_TENANT_TOKEN : $EM_TENANT_TOKEN"
  fi
  if [[ $RUN_CREATE_DEVICE == 1 ]]; then
    echo "Create Device"
    edgeEdgeManagerCreateDevice
  fi
  if [[ $RUN_CREATE_PACKAGES == 1 ]]; then
    echo "Creating Packages"
    createPackages $EDGE_APP_NAME
  fi
  if [[ $RUN_CREATE_CONFIGIURATION == 1 ]]; then
    echo "Upload Configuration package"
    PACKAGE_NAME="$EDGE_APP_NAME-config"
    PACKAGE_DESCRIPTION="Package for configuration for $EDGE_APP_NAME"
    PACKAGE_CONTENT_FILE="$REPO_NAME/$EDGE_APP_NAME-config.zip"
    createEMPackage "configuration"
  fi
  if [[ $RUN_CREATE_APPLICATION == 1 ]]; then
    echo "Upload Application package"
    PACKAGE_NAME="$EDGE_APP_NAME"
    PACKAGE_DESCRIPTION="Package for Application $EDGE_APP_NAME"
    PACKAGE_CONTENT_FILE="$REPO_NAME/$EDGE_APP_NAME.tar.gz"
    createEMPackage "multi-container-app"
  fi

  if [[ $RUN_START_ENROLLMENT == 1 ]]; then
    echo "Starting Enrollment"
    startEnrollement
  fi
  if [[ $RUN_SCHEDULE_PACKAGE == 1 ]]; then
    deployPackageToDevice
  fi
}

function edgeEdgeManagerCreateDevice() {
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "$EM_TENANT_TOKEN"
  fi
  if [[ ! -n $DEVICE_ID ]]; then
    read -p "Enter your Device ID> " DEVICE_ID
  fi
  device_model_response=$(curl -X POST "https://em-api-apidocs.run.aws-usw02-pr.ice.predix.io/emapi/beta/device-management/models" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption" -H "Content-Type: application/json" -d "{ \"description\": \"Predix Edge Model\", \"memoryGB\": 1, \"modelId\": \"PredixEdge\", \"os\": \"Yocto Linux\", \"coreNum\": 1, \"processor\": \"Core\", \"storageGB\": 5}")
  echo "$device_model_response"
  DEVICE_REQUEST_STATUS=$(curl --write-out %{http_code} --silent --output /dev/null -X GET "https://em-api-apidocs.run.aws-usw02-pr.ice.predix.io/emapi/beta/device-management/devices/$DEVICE_ID" -H "Accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption")
  if [[ $DEVICE_REQUEST_STATUS == 404 ]]; then
    __append_new_line_log "Device $DEVICE_ID not found. Creating the device now..." "$logDir"
    echo "Device $DEVICE_ID not found. Creating the device now..." >> $SUMMARY_TEXTFILE
    if [[ ! -n $DEVICE_SECRET ]]; then
      read -p "Enter your Device Secret> " -s DEVICE_SECRET
    fi
    responseCurl=$(curl -sw '%{http_code}' -X POST "$EM_DEVICE_MANAGEMENT_URL" -H "accept: */*" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"description\": \"Edge OS Device\", \"deviceId\": \"$DEVICE_ID\", \"dockerEnabled\": true, \"modelId\": \"PredixEdge\", \"name\": \"$DEVICE_ID\", \"sharedSecret\": \"$DEVICE_SECRET\"}")
    echo ""
    __append_new_line_log "responseCurl : $responseCurl" "$logDir"
  else
    __append_new_line_log "device Already created" "$logDir"
    echo "Device Already created" >> $SUMMARY_TEXTFILE
  fi
}

function createEMPackage {
  __validate_num_arguments 1 $# "\"createEMPackage()\" expected in order:  Package Type." "$logDir"
  echo "EM_TENANT_TOKEN : $EM_TENANT_TOKEN"
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "$EM_TENANT_TOKEN"
  fi
  PACKAGE_TYPE="$1"
  if [[ ! -n $PACKAGE_TYPE ]]; then
    read -p "Enter Package Type (application|configuration)> " PACKAGE_TYPE
    export PACKAGE_TYPE
  fi
  if [[ ! -n $PACKAGE_NAME ]]; then
    read -p "Enter Package Name> " PACKAGE_NAME
    export PACKAGE_NAME
  fi
  if [[ ! -n $PACKAGE_DESCRIPTION ]]; then
    read -p "Enter Package Description> " PACKAGE_DESCRIPTION
    export PACKAGE_DESCRIPTION
  fi
  if [[ ! -n $PACKAGE_VERSION ]]; then
    read -p "Enter Package Version> " PACKAGE_VERSION
    export PACKAGE_VERSION
  fi
  echo "EM_PACKAGE_MANAGEMENT_URL : $EM_PACKAGE_MANAGEMENT_URL"
  responseCurl=$(curl -X GET "$EM_PACKAGE_MANAGEMENT_URL/$PACKAGE_TYPE/$PACKAGE_NAME/$PACKAGE_VERSION" -H "Accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption")
  echo "query package response : $responseCurl"
  ERROR_CODE=$( echo "$responseCurl" | jq -r .code)
  if [[ $ERROR_CODE == 404 ]]; then
    echo "$PACKAGE_TYPE"
    responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption" -H "Content-Type: application/json" -d "{ \"agentType\": \"EdgeAgent\", \"description\": \"$PACKAGE_DESCRIPTION\", \"name\": \"$PACKAGE_NAME\", \"totalBytes\": 0, \"type\": \"$PACKAGE_TYPE\", \"vendor\": \"predix-adoption\", \"version\": \"$PACKAGE_VERSION\"}");
    echo "create package response : $responseCurl"
    ERROR_CODE=$( echo "$responseCurl" | jq -r .code)
    while [ $ERROR_CODE == 409 ]; do
        echo "Package version $PACKAGE_NAME : $PACKAGE_TYPE : $PACKAGE_VERSION already exists"
        read -p "Enter different Package Version> " PACKAGE_VERSION
        export PACKAGE_VERSION
        echo "$PACKAGE_TYPE"
        responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption" -H "Content-Type: application/json" -d "{ \"agentType\": \"EdgeAgent\", \"description\": \"$PACKAGE_DESCRIPTION\", \"name\": \"$PACKAGE_NAME\", \"totalBytes\": 0, \"type\": \"$PACKAGE_TYPE\", \"vendor\": \"predix-adoption\", \"version\": \"$PACKAGE_VERSION\"}");
        echo "create package response : $responseCurl"
        ERROR_CODE=$( echo "$responseCurl" | jq -r .code)
        echo "$ERROR_CODE : $ERROR_CODE"
    done
    UPLOAD_ID=$( __jsonval "$responseCurl" "uploadId" )
    if [[ -n $UPLOAD_ID ]]; then
        uploadPackageContent $UPLOAD_ID
    else
      echo "Failed to create package.. Exiting"
      exit 1
    fi
  else
    echo "Package $PACKAGE_NAME : $PACKAGE_DESCRIPTION :$PACKAGE_VERSION already exists"
  fi

}

function uploadPackageContent {
  UPLOAD_ID="$1"
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
  fi
  #statements
  if [[ ! -n $PACKAGE_TYPE ]]; then
    read -p "Enter Package Type (application|configuration)> " PACKAGE_TYPE
    export PACKAGE_TYPE
  fi
  pwd
  if [[ ! -n $PACKAGE_CONTENT_FILE ]]; then
    read -p "Enter Full path of the content ($PACKAGE_TYPE) file> " PACKAGE_CONTENT_FILE
    export PACKAGE_CONTENT_FILE
  fi

  case "$PACKAGE_TYPE" in
    "application"|"multi-container-app" )
      responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption" -H "Content-Type: multipart/form-data" -F "binary=@$PACKAGE_CONTENT_FILE;type=application/x-gzip")
      ;;
    "configuration" )
      responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption" -H "Content-Type: multipart/form-data" -F "binary=@$PACKAGE_CONTENT_FILE;type=application/zip")
      ;;
  esac
  echo "$responseCurl"
  getPackageUploadStatus $UPLOAD_ID
  if [[ "$PACKAGE_UPLOAD_STATUS" == "complete" ]]; then
    deployPackageToDevice
  fi

}

function getEMUserToken() {
  if [[ ! -n $EM_TENANT_ID ]]; then
    read -p "Enter the Edge Manager Tenant Id> " EM_TENANT_ID
    export EM_TENANT_ID
  fi

  EDGE_MANAGER_URL="https://$EM_TENANT_ID.edgemanager.run.aws-usw02-pr.ice.predix.io"
  export EDGE_MANAGER_URL
  if [[ ! -n $TRUSTED_ISSUER_ID ]]; then
      read -p "Enter the UAA Zone Id> " UAA_ZONE_ID
      TRUSTED_ISSUER_ID="https://$UAA_ZONE_ID.predix-uaa.run.aws-usw02-pr.ice.predix.io"
      export TRUSTED_ISSUER_ID
  fi

  if [[ ! -n $UAA_CLIENTID_GENERIC ]]; then
    read -p "Enter your UAA Client ID> " UAA_CLIENTID_GENERIC
    export UAA_CLIENTID_GENERIC
  fi
  if [[ ! -n $UAA_CLIENTID_GENERIC_SECRET ]]; then
    read -p "Enter your UAA Client Secret> " -s UAA_CLIENTID_GENERIC_SECRET
    export UAA_CLIENTID_GENERIC_SECRET
  fi
  if [[ ! -n $UAA_USER_GENERIC ]]; then
    read -p "Enter your UAA User ID> " UAA_USER_GENERIC
    export UAA_USER_GENERIC
  fi
  if [[ ! -n $UAA_USER_PASSWORD ]]; then
    read -p "Enter your UAA User Secret> " -s UAA_USER_PASSWORD
    export UAA_USER_PASSWORD
  fi
  EM_TENANT_TOKEN=$(__getUaaUserToken $TRUSTED_ISSUER_ID $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $UAA_USER_GENERIC $UAA_USER_PASSWORD)
  export EM_TENANT_TOKEN
}

function getPackageUploadStatus {
  __validate_num_arguments 1 $# "\"getPackageUploadStatus\" expected in order: String of uploadId used to get status of package upload" "$logDir"
  UPLOAD_ID="$1"
  status="pending"
  while [[ "$status" == "pending" ]]; do
    responseCurl=$(curl --silent -X GET "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption")
    status=$( echo "$responseCurl" | jq -r .status)
    echo "status : $status"
  done
  export PACKAGE_UPLOAD_STATUS="$status"
}

function deployPackageToDevice {
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "$EM_TENANT_TOKEN"
  fi
  if [[ ! -n $DEVICE_ID ]]; then
    read -p "Enter your Device ID> " DEVICE_ID
    export DEVICE_ID
  fi

}

function createPackages {
  echo "1111"
	cd $REPO_NAME
  pwd
  echo "Creating Packages for EdgeManager Repository for $EDGE_APP_NAME"
  APP_NAME_TAR="$EDGE_APP_NAME.tar.gz"
  if [[ -e config/config-cloud-gateway.json ]]; then
    if [[ "$TIMESERIES_INGEST_URI" == "" ]]; then
      TIMESERIES_INGEST_URI="wss://gateway-predix-data-services.run.aws-usw02-pr.ice.predix.io/v1/stream/messages"
    fi
    if [[ "$TIMESERIES_QUERY_URI" == "" ]]; then
      TIMESERIES_QUERY_URI="https://time-series-store-predix.run.aws-usw02-pr.ice.predix.io/v1/datapoints"
    fi
    if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
      read -p "Enter Timeseries Zone Id>" TIMESERIES_ZONE_ID
    fi
    echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
    __find_and_replace ".*predix_zone_id\":.*" "          \"predix_zone_id\": \"$TIMESERIES_ZONE_ID\"," "config/config-cloud-gateway.json" "$quickstartLogDir"
    echo "proxy_url : $http_proxy"
    __find_and_replace ".*proxy_url\":.*" "          \"proxy_url\": \"$http_proxy\"" "config/config-cloud-gateway.json" "$quickstartLogDir"
  fi
  echo "Creating a images.tar with required images"
  rm -rf images.tar
  IMAGES_LIST=""
  for img in $(cat docker-compose.yml | grep image: | awk -F" " '{print $2}' | tr -d "\"");
  do
    IMAGES_LIST="$IMAGES_LIST $img"
  done
  echo "$IMAGES_LIST"
  docker save -o images.tar $IMAGES_LIST
  rm -rf "$APP_NAME_TAR"
  echo "Creating $APP_NAME_TAR with docker-compose.yml"
  tar -czvf $APP_NAME_TAR images.tar docker-compose.yml

  APP_NAME_CONFIG="$EDGE_APP_NAME-config.zip"

  if [[ -e config ]]; then
    rm -rf $APP_NAME_CONFIG
    echo "Compressing the configurations."
    cd config
    zip -X -r ../$APP_NAME_CONFIG *.json
    cd ../
  fi
  ls -lrt
}

function startEnrollement {
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "$EM_TENANT_TOKEN"
  fi
  if [[ ! -n $DEVICE_ID ]]; then
    read -p "Enter your Device ID> " DEVICE_ID
    export DEVICE_ID
  fi
  if [[ ! -n $DEVICE_SECRET ]]; then
    read -p "Enter your Device Secret> " -s DEVICE_SECRET
  fi
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
    spawn scp -o \"StrictHostKeyChecking=no\" $rootDir/bash/scripts/edge-starter-enrollment.sh $LOGIN_USER@$IP_ADDRESS:/mnt/data/downloads
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
    send \"su eauser /mnt/data/downloads/edge-starter-enrollment.sh $DEVICE_ID $DEVICE_SECRET $EDGE_MANAGER_URL\r\"
    set timeout 20
    expect \"*\# \"
    send \"exit\r\"
    expect eof
  "
}
