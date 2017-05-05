#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to clone the repo,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

trap "trap_ctrlc" 2

GIT_DIR="$rootDir/data-exchange-simulator"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function build-basic-app-data-simulator-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-data-simulator.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Data-Simulator Back-end Microservice" "-" "$logDir"

  # Get the UAA environment variables (VCAPS)
  fetchVCAPSInfo $1

  cd "$rootDir"
  if [[ "$USE_DATA_SIMULATOR" == "1" ]]; then
    # Checkout the repo
    getGitRepo "data-exchange-simulator"
    cd data-exchange-simulator

    #Checkout the tag if provided by user
    #__checkoutTags "$GIT_DIR"

    # Edit the manifest.yml files

    #    a) Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $DATA_SIMULATOR_APP_NAME" "manifest.yml" "$logDir"

    #    b) Add the services to bind to the application
    __find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-uaa" "- $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-timeseries" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"

    #    c) Set the clientid and base64ClientCredentials
    UAA_HOSTNAME=$(echo $uaaURL | awk -F"/" '{print $3}')
    __find_and_replace "predix_uaa_name: .*" "predix_uaa_name: $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{uaaService}" "$UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_asset_name : .*" "predix_asset_name: $ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{assetService}" "$ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_oauth_clientId : .*" "predix_oauth_clientId: $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"
    CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
    __find_and_replace "predix_fdh_restHost : .*" "predix_fdh_restHost: $DATAEXCHANGE_APP_NAME"".run.$CLOUD_ENDPONT" "manifest.yml" "$logDir"

    cat manifest.yml

    # Push the application
    if [[ $USE_TRAINING_UAA -eq 1 ]]; then
      sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
    fi
    __append_new_head_log "Retrieving the application $DATA_SIMULATOR_APP_NAME" "-" "$logDir"
    if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
      mvn clean package -U -s $MAVEN_SETTINGS_FILE
    else
      mvn clean dependency:copy -s $MAVEN_SETTINGS_FILE
    fi
    __append_new_head_log "Deploying the application $DATA_SIMULATOR_APP_NAME" "-" "$logDir"
    if cf push; then
      __append_new_line_log "Successfully deployed!" "$logDir"
    else
      __append_new_line_log "Failed to deploy application. Retrying..." "$logDir"
      if cf push; then
        __append_new_line_log "Successfully deployed!" "$logDir"
      else
        __error_exit "There was an error pushing using: \"cf push\"" "$logDir"
      fi
    fi
    APP_URL=$(cf app $DATA_SIMULATOR_APP_NAME | grep urls | awk -F" " '{print $2}')
    cd ..
  fi

  echo "sleep for 30 seconds so we can generate some data"
  sleep 30
  cf stop $DATA_SIMULATOR_APP_NAME


  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Back-end Data Simulator Spring Boot Microservice App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed DataSimulator back-end microservice to the cloud and updated the manifest file with UAA, Asset and DataExchange info"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$DATA_SIMULATOR_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'cf env "$DATA_SIMULATOR_APP_NAME"' to view info about your back-end microservice, and the bound UAA and Asset" >> $SUMMARY_TEXTFILE
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Note: The simulator is turned on for only 30 seconds.  To generate more time series data please turn on your simulator, e.g. using the predix cli, px start thomas-edison-data-exchange-simulator"  >> $SUMMARY_TEXTFILE

}
