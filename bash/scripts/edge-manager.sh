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
  ENVIRONMENT_FILE=${ENVIRONMENT_FILE:-$DEFAULT_EM_ENVIRONMENT_FILE}
  if [[ ! -e $ENVIRONMENT_FILE ]]; then
    echo "" > $ENVIRONMENT_FILE
  fi
  source $ENVIRONMENT_FILE
  echo "EDGE_APP_NAME : $EDGE_APP_NAME"
  echo "ASSET_NAME : $ASSET_NAME"
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
  fi
  if [[ $RUN_CREATE_DEVICE == 1 ]]; then
    echo "Create Device"
    edgeEdgeManagerCreateDevice
  fi
  if [[ $RUN_CREATE_PACKAGES == 1 ]]; then
    echo "Creating Packages"
    createPackages $EDGE_APP_NAME
  fi
  PACKAGE_VERSION=$(jq -r '.version' version.json)
  if [[ $RUN_CREATE_APPLICATION == 1 ]]; then
    echo "Upload Application package"
    PACKAGE_NAME="$EDGE_APP_NAME"
    PACKAGE_DESCRIPTION="Package for Application $EDGE_APP_NAME"
    PACKAGE_CONTENT_FILE="$EDGE_APP_NAME.tar.gz"
    createEMPackage "multi-container-app"
  fi
  if [[ $RUN_CREATE_CONFIGIURATION == 1 ]]; then
    echo "Upload Configuration package"
    PACKAGE_NAME="$EDGE_APP_NAME-$ASSET_NAME-config"
    PACKAGE_DESCRIPTION="Package for configuration for $EDGE_APP_NAME, Asset $ASSET_NAME"
    PACKAGE_CONTENT_FILE="$EDGE_APP_NAME-$ASSET_NAME-config.zip"
    createEMPackage "configuration"
  fi
  if [[ $SKIP_ENROLLMENT == 0 ]]; then
    echo "Starting Enrollment"
    startEnrollement
  fi
  if [[ $RUN_SCHEDULE_PACKAGE == 1 ]]; then
    # Deploy Application first
    PACKAGE_NAME="$EDGE_APP_NAME"
    echo "Deploying the Application $PACKAGE_NAME $PACKAGE_VERSION"
    deployPackageToDevice "multi-container-app" $EDGE_APP_NAME $PACKAGE_VERSION

    #Deploy Configuration
    PACKAGE_NAME="$EDGE_APP_NAME-$ASSET_NAME-config"
    echo "Deploying the Application $PACKAGE_NAME $PACKAGE_VERSION"
    deployPackageToDevice "configuration" $EDGE_APP_NAME $PACKAGE_VERSION
  fi
}

function deployPackageToDevice {
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    #echo "$EM_TENANT_TOKEN"
  fi
  getDeviceId
  echo "DeviceId=$DEVICE_ID"
  curl -X POST "$EM_PACKAGE_MANAGEMENT_URL/deploy" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"deviceFilter\": \"deviceId eq \\\"$DEVICE_ID\\\"\", \"name\": \"$PACKAGE_NAME\", \"appInstanceId\": \"$2\", \"timeout\": 0, \"type\": \"$1\", \"version\": \"$3\"}"
}

function getDeviceId() {
  if [[ ! -n $DEVICE_ID ]]; then
    echo "In Edge Manager, you will see a list of devices. This script will create a Device using the EM API."
    echo "The device represents the equipment on which your Predix Edge Application will run."
    echo "In this tutorial, the Device is the Predix Edge OS Virtual Machine running in VMWare on your computer"
    echo "Your device id is the unique ID used in Edge Manager, e.g. thomas-edison-predix-edge-os-2.1.0."
    read -p "Enter your Device ID($DEFAULT_DEVICE_ID)> " DEVICE_ID
    DEVICE_ID=${DEVICE_ID:-$DEFAULT_DEVICE_ID}
    while true; do
      if [ "$DEVICE_ID" == "${DEVICE_ID/\./}" ]; then
        export DEVICE_ID
        break;
      else
        echo "Device Id cannot have dot(.)"
        read -p "Enter a unique Device Id with dash (-) in place of underscore(.)> " INSTANCE_PREPENDER
      fi
    done
    DEFAULT_DEVICE_ID=$DEVICE_ID
    declare -p DEFAULT_DEVICE_ID >> $ENVIRONMENT_FILE
  fi
}

function getDeviceSecret() {
  pwd
  echo "DEFAULT_DEVICE_SECRET=$DEFAULT_DEVICE_SECRET"
  if [[ ! -n $DEVICE_SECRET ]]; then
    echo "Device Enrollment generates a Certificate.  Set a Secret for your Certificate Enrollment and remember it"
    read -p "Enter your Device Secret($DEFAULT_DEVICE_SECRET)> " -s DEVICE_SECRET
    DEVICE_SECRET=${DEVICE_SECRET:-$DEFAULT_DEVICE_SECRET}
    DEFAULT_DEVICE_SECRET=$DEVICE_SECRET
    export DEVICE_SECRET
    declare -p DEFAULT_DEVICE_SECRET >> $ENVIRONMENT_FILE
    echo ""
  fi
}

function edgeEdgeManagerCreateDevice() {
  echo "edgeEdgeManagerCreateDevice"
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    #echo "$EM_TENANT_TOKEN"
  fi

  getDeviceId
  echo "DeviceId=$DEVICE_ID"

  device_model_response=$(curl -s -X POST "https://em-api-apidocs.run.aws-usw02-pr.ice.predix.io/emapi/beta/device-management/models" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"description\": \"Predix Edge Model\", \"memoryGB\": 1, \"modelId\": \"PredixEdge\", \"os\": \"Yocto Linux\", \"coreNum\": 1, \"processor\": \"Core\", \"storageGB\": 5}")
  echo "device_model_response : $device_model_response"
  DEVICE_REQUEST_RESPONSE=$(curl -s -X GET "https://em-api-apidocs.run.aws-usw02-pr.ice.predix.io/emapi/beta/device-management/devices/$DEVICE_ID" -H "Accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID")
  echo "DEVICE_REQUEST_RESPONSE : $DEVICE_REQUEST_RESPONSE"
  DEVICE_REQUEST_STATUS=$(echo $DEVICE_REQUEST_RESPONSE | jq -r '.code')
  echo "DEVICE_REQUEST_STATUS : $DEVICE_REQUEST_STATUS"
  if [[ $DEVICE_REQUEST_STATUS == "" ]]; then
    __append_new_line_log "device Already created" "$logDir"
    echo "Device Already created" >> $SUMMARY_TEXTFILE
  elif [[ $DEVICE_REQUEST_STATUS == 401 ]]; then
    __append_new_line_log "Unable to get a valid token" "$logDir"
    echo "Unable to get a valid token" >> $SUMMARY_TEXTFILE
    exit 1
  elif [[ $DEVICE_REQUEST_STATUS == 404 ]]; then
    __append_new_line_log "Device $DEVICE_ID not found. Creating the device now..." "$logDir"
    echo "Device $DEVICE_ID not found. Creating the device now..." >> $SUMMARY_TEXTFILE
    getDeviceSecret
    responseCurl=$(curl -X POST "$EM_DEVICE_MANAGEMENT_URL" -H "accept: */*" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"description\": \"Edge OS Device\", \"deviceId\": \"$DEVICE_ID\", \"dockerEnabled\": true, \"platform\": \"Predix Edge\", \"modelId\": \"PredixEdge\", \"name\": \"$DEVICE_ID\", \"sharedSecret\": \"$DEVICE_SECRET\"}")
    __append_new_line_log "responseCurl : $responseCurl" "$logDir"
  else
    echo "Other error Check the reponse"
    echo "$DEVICE_REQUEST_RESPONSE"
  fi
}

function createEMPackage {
  __validate_num_arguments 1 $# "\"createEMPackage()\" expected in order:  Package Type." "$logDir"
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
  responseCurl=$(curl -X GET "$EM_PACKAGE_MANAGEMENT_URL/$PACKAGE_TYPE/$PACKAGE_NAME/$PACKAGE_VERSION" -H "Accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID")
  echo "query package response : $responseCurl"
  ERROR_CODE=$( echo "$responseCurl" | jq -r .code)
  if [[ $ERROR_CODE == 404 ]]; then
    echo "$PACKAGE_TYPE"
    responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"agentType\": \"EdgeAgent\", \"description\": \"$PACKAGE_DESCRIPTION\", \"name\": \"$PACKAGE_NAME\", \"totalBytes\": 0, \"type\": \"$PACKAGE_TYPE\", \"vendor\": \"$EM_TENANT_ID\", \"version\": \"$PACKAGE_VERSION\"}");
    echo "create package response : $responseCurl"
    ERROR_CODE=$( echo "$responseCurl" | jq -r .code)
    while [ $ERROR_CODE == 409 ]; do
        echo "Package version $PACKAGE_NAME : $PACKAGE_TYPE : $PACKAGE_VERSION already exists"
        read -p "Enter different Package Version> " PACKAGE_VERSION
        export PACKAGE_VERSION
        echo "$PACKAGE_TYPE"
        responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: application/json" -d "{ \"agentType\": \"EdgeAgent\", \"description\": \"$PACKAGE_DESCRIPTION\", \"name\": \"$PACKAGE_NAME\", \"totalBytes\": 0, \"type\": \"$PACKAGE_TYPE\", \"vendor\": \"$EM_TENANT_ID\", \"version\": \"$PACKAGE_VERSION\"}");
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
      responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: multipart/form-data" -F "binary=@$PACKAGE_CONTENT_FILE;type=application/x-gzip")
      ;;
    "configuration" )
      responseCurl=$(curl -X POST "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID" -H "Content-Type: multipart/form-data" -F "binary=@$PACKAGE_CONTENT_FILE;type=application/zip")
      ;;
  esac
  getPackageUploadStatus $UPLOAD_ID
}

function getEMUserToken() {
  if [[ -e $ENVIRONMENT_FILE ]]; then
    source $ENVIRONMENT_FILE
  fi
  echo "EM_TENANT_ID : $EM_TENANT_ID"
  if [[ ! -n $EM_TENANT_ID ]]; then
    echo "The tenant id is the first part of the edge-manager url.  e.g. in this url, thomas-edison is the tenant id.  https://thomas-edison.edgemanager.run.aws-usw02-pr.ice.predix.io/dashboard"
    read -p "Enter the Edge Manager Tenant Id($DEFAULT_EM_TENANT_ID)> " EM_TENANT_ID
    EM_TENANT_ID=${EM_TENANT_ID:-$DEFAULT_EM_TENANT_ID}
    export EM_TENANT_ID
    DEFAULT_EM_TENANT_ID=$EM_TENANT_ID
    declare -p DEFAULT_EM_TENANT_ID >> $ENVIRONMENT_FILE
  fi

  EDGE_MANAGER_URL="https://$EM_TENANT_ID.edgemanager.run.aws-usw02-pr.ice.predix.io"
  export EDGE_MANAGER_URL
  echo "EM_UAA_ZONE_ID=$EM_UAA_ZONE_ID"
  if [[ ! -n $EM_UAA_ZONE_ID ]]; then
      echo "The UAA Zone Id is found in the welcome email you received for Edge Manager.  APM users who have tied Edge Manager to the same UAA, go to Admin/Setup menu and the zone-id is the GUID in the Token Request URL."
      read -p "Enter the UAA Zone Id($DEFAULT_EM_UAA_ZONE_ID)> " EM_UAA_ZONE_ID
      EM_UAA_ZONE_ID=${EM_UAA_ZONE_ID:-$DEFAULT_EM_UAA_ZONE_ID}
      DEFAULT_EM_UAA_ZONE_ID=$EM_UAA_ZONE_ID
      export EM_UAA_ZONE_ID
      declare -p DEFAULT_EM_UAA_ZONE_ID >> $ENVIRONMENT_FILE
  fi
  EM_TRUSTED_ISSUER_ID="https://$EM_UAA_ZONE_ID.predix-uaa.run.aws-usw02-pr.ice.predix.io"
  export EM_TRUSTED_ISSUER_ID
  if [[ ! -n $EM_CLIENT_ID ]]; then
    read -p "Enter your Edge Manager Client ID($DEFAULT_EM_CLIENT_ID)> " EM_CLIENT_ID
    EM_CLIENT_ID=${EM_CLIENT_ID:-$DEFAULT_EM_CLIENT_ID}
    DEFAULT_EM_CLIENT_ID=$EM_CLIENT_ID
    export EM_CLIENT_ID
    declare -p DEFAULT_EM_CLIENT_ID >> $ENVIRONMENT_FILE
  fi
  if [[ ! -n $EM_CLIENT_SECRET ]]; then
    read -p "Enter your Edge Manager Client Secret($DEFAULT_EM_CLIENT_SECRET)> " -s EM_CLIENT_SECRET
    EM_CLIENT_SECRET=${EM_CLIENT_SECRET:-$DEFAULT_EM_CLIENT_SECRET}
    DEFAULT_EM_CLIENT_SECRET=$EM_CLIENT_SECRET
    export EM_CLIENT_SECRET
    declare -p DEFAULT_EM_CLIENT_SECRET >> $ENVIRONMENT_FILE
    echo "********"
  fi
  if [[ ! -n $EM_USER_ID ]]; then
    read -p "Enter your Edge Manager Tenant User ID($DEFAULT_EM_USER_ID)> " EM_USER_ID
    EM_USER_ID=${EM_USER_ID:-$DEFAULT_EM_USER_ID}
    DEFAULT_EM_USER_ID=$EM_USER_ID
    export EM_USER_ID
    declare -p DEFAULT_EM_USER_ID >> $ENVIRONMENT_FILE
  fi
  if [[ ! -n $EM_USER_PASSWORD ]]; then
    read -p "Enter your Edge Manager Tenant User Secret($DEFAULT_EM_USER_PASSWORD)> " -s EM_USER_PASSWORD
    EM_USER_PASSWORD=${EM_USER_PASSWORD:-$DEFAULT_EM_USER_PASSWORD}
    DEFAULT_EM_USER_PASSWORD=$EM_USER_PASSWORD
    export EM_USER_PASSWORD
    declare -p DEFAULT_EM_USER_PASSWORD >> $ENVIRONMENT_FILE
    echo "********"
  fi
  EM_TENANT_TOKEN=$(__getUaaUserToken $EM_TRUSTED_ISSUER_ID $EM_CLIENT_ID $EM_CLIENT_SECRET $EM_USER_ID $EM_USER_PASSWORD)
  export EM_TENANT_TOKEN
}

function getPackageUploadStatus {
  __validate_num_arguments 1 $# "\"getPackageUploadStatus\" expected in order: String of uploadId used to get status of package upload" "$logDir"
  UPLOAD_ID="$1"
  status="pending"
  while [[ "$status" == "pending" ]]; do
    responseCurl=$(curl --silent -X GET "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: $EM_TENANT_ID")
    status=$( echo "$responseCurl" | jq -r .status)
    echo "status : $status"
  done
  export PACKAGE_UPLOAD_STATUS="$status"
}

function createPackages {
  pwd
  if [[ ! -e $REPO_NAME ]]; then
    echo "directory=$REPO_NAME is not there.  You should run this script after running the quickstart-edge-ref-app-local.sh script"
    exit 1
  fi
  cd $REPO_NAME
  pwd
  echo "Creating Packages for EdgeManager Repository for $EDGE_APP_NAME"
  APP_NAME_TAR="$EDGE_APP_NAME.tar.gz"
  if [[ -e config/config-cloud-gateway.json ]]; then
    if [[ "$SKIP_PREDIX_SERVICES" == "false" ]]; then
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

  APP_NAME_CONFIG="$EDGE_APP_NAME-$ASSET_NAME-config.zip"

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
  echo "startEnrollment"
  pwd
  cd $rootDir
  pwd
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
    echo "$EM_TENANT_TOKEN"
  fi

  getDeviceId
  echo "DeviceId=$DEVICE_ID"

  getDeviceSecret

  if [[ ! -n $IP_ADDRESS ]]; then
    read -p "Enter the IP Address of Edge OS($DEFAULT_IP_ADDRESS)> " IP_ADDRESS
    IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_IP_ADDRESS}
    DEFAULT_IP_ADDRESS=$IP_ADDRESS
    export IP_ADDRESS
    declare -p DEFAULT_IP_ADDRESS >> $ENVIRONMENT_FILE
  fi
  if [[ ! -n $LOGIN_USER ]]; then
    read -p "Enter the username for Edge OS($DEFAULT_LOGIN_USER)> " LOGIN_USER
    LOGIN_USER=${LOGIN_USER:-$DEFAULT_LOGIN_USER}
    DEFAULT_LOGIN_USER=$LOGIN_USER
    export LOGIN_USER
    declare -p DEFAULT_LOGIN_USER >> $ENVIRONMENT_FILE
  fi
  if [[ ! -n $LOGIN_PASSWORD ]]; then
    read -p "Enter your user password($DEFAULT_LOGIN_PASSWORD)> " -s LOGIN_PASSWORD
    LOGIN_PASSWORD=${LOGIN_PASSWORD:-$DEFAULT_LOGIN_PASSWORD}
    DEFAULT_LOGIN_PASSWORD=$LOGIN_PASSWORD
    export LOGIN_PASSWORD
    declare -p DEFAULT_LOGIN_PASSWORD >> $ENVIRONMENT_FILE
  fi
  echo "$IP_ADDRESS : $IP_ADDRESS"
  if [[ $(ssh-keygen -F $IP_ADDRESS | wc -l | tr -d " ") != 0 ]]; then
		ssh-keygen -R $IP_ADDRESS
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
    send \"su - eauser\r\"
    expect \"*\# \"
    send \"echo 'Checking for Internet access'\r\"
    expect \"*\# \"
    send \"curl google.com\r\"
    expect \"*\# \"
    send \"echo 'You should see \'The document has moved\'.  If curl fails, you will see \'Could not resolve host: google.com\'.  If curl fails, use PETC console to set the proxy variables.  To open PETC, using a browser, go to http://ip-address-of-vm, login with admin/admin'\r\"
    expect \"*\# \"
    send \"echo 'Then re-run this script'\r\"
    expect \"*\# \"
    send \"exit\r\"
    expect \"*\# \"
    send \"su eauser /mnt/data/downloads/edge-starter-enrollment.sh $DEVICE_ID $DEVICE_SECRET $EDGE_MANAGER_URL\r\"
    set timeout 20
    expect \"*\# \"
    send \"exit\r\"
    expect eof
  "
}
