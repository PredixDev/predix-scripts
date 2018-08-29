#!/bin/bash
set -x
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
  if [[ ! -n $EM_TENANT_TOKEN ]]; then
    getEMUserToken
  fi
  if [[ $RUN_CREATE_DEVICE == 1 ]]; then
    echo "Create Device"
    edgeEdgeManagerCreateDevice

  fi

  if [[ $RUN_CREATE_CONFIGIURATION == 1 ]]; then
    echo "Upload Configuration package"
    PACKAGE_NAME="$APP_NAME\_Config"
    PACKAGE_DESCRIPTION="Package for configuration for $APP_NAME"
    PACKAGE_CONTENT_FILE="$REPO_NAME/$APP_NAME-config.zip"
    createEMPackage "configuration"
  fi

  if [[ $RUN_CREATE_APPLICATION == 1 ]]; then
    echo "Upload Application package"
    PACKAGE_NAME="$APP_NAME"
    PACKAGE_DESCRIPTION="Package for Application $APP_NAME"
    PACKAGE_CONTENT_FILE="$REPO_NAME/$APP_NAME.tar.gz"
    createEMPackage "multi-container-app"
  fi

  if [[ $RUN_START_ENROLLMENT == 1 ]]; then
    echo "Starting Enrollment"
    startEnrollement
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
}

function getEMUserToken() {
  if [[ ! -n $EM_TENANT_ID ]]; then
    read -p "Enter the Edge Manager Tenant Id> " EM_TENANT_ID
    export EM_TENANT_ID
  fi

  EDGE_MANAGER_URL="https://$EM_TENANT_ID.edgemanager.run.aws-usw02-pr.ice.predix.io"
  export EDGE_MANAGER_URL
  if [[ ! -n $EM_UAA_ZONE_ID ]]; then
      read -p "Enter the UAA Zone Id> " EM_UAA_ZONE_ID
      export EM_UAA_ZONE_ID
  fi

  EDGE_MANAGER_UAA_URL="https://$EM_UAA_ZONE_ID.predix-uaa.run.aws-usw02-pr.ice.predix.io"
  if [[ ! -n $EM_CLIENT_ID ]]; then
    read -p "Enter your UAA Client ID> " EM_CLIENT_ID
    export EM_CLIENT_ID
  fi
  if [[ ! -n $EM_CLIENT_SECRET ]]; then
    read -p "Enter your UAA Client Secret> " -s EM_CLIENT_SECRET
    export EM_CLIENT_SECRET
  fi
  if [[ ! -n $EM_USER_ID ]]; then
    read -p "Enter your UAA User ID> " EM_USER_ID
    export EM_USER_ID
  fi
  if [[ ! -n $EM_USER_PASSWORD ]]; then
    read -p "Enter your UAA User Secret> " -s EM_USER_PASSWORD
    export EM_USER_SECRET
  fi
  EM_TENANT_TOKEN=$(__getUaaUserToken $EDGE_MANAGER_UAA_URL $EM_CLIENT_ID $EM_CLIENT_SECRET $EM_USER_ID $EM_USER_PASSWORD)
  export EM_TENANT_TOKEN
}

function getPackageUploadStatus {
  __validate_num_arguments 1 $# "\"getPackageUploadStatus\" expected in order: String of uploadId used to get status of package upload" "$logDir"
  UPLOAD_ID="$1"
  responseCurl=$(curl --silent -X GET "$EM_PACKAGE_MANAGEMENT_URL/uploads/$UPLOAD_ID" -H "accept: application/json" -H "Authorization: Bearer $EM_TENANT_TOKEN" -H "Predix-Zone-Id: predix-adoption")
  status=$( echo "$responseCurl" | jq -r .status)
  echo "Package upload Status : $status"
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
