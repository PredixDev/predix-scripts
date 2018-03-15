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

GIT_DIR="$rootDir/rmd-orchestration"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function digital-twin-rmdorchestration-main() {
  __validate_num_arguments 1 $# "\"digital-twin-rmdorchestration.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy RMD Orchestration" "-" "$logDir"

  cd "$rootDir"
  if [[ "$USE_RMD_ORCHESTRATION" == "1" ]]; then
    getGitRepo "rmd-orchestration"
    cd rmd-orchestration

    # Edit the manifest.yml files

    cd fieldchangedevent-consumer
    #    a) Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $RMD_ORCHESTRATION_APP_NAME" "manifest.yml" "$logDir"

    #    b) Add the services to bind to the application
    __find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-uaa" "- $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"

    #    c) Set the clientid and base64ClientCredentials
    UAA_HOSTNAME=$(echo $uaaURL | awk -F"/" '{print $3}')
    __find_and_replace "predix_uaa_name: .*" "predix_uaa_name: $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{uaaService}" "$UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{rabbitMQService}" "$RABBITMQ_SERVICE_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{afService}" "$ANALYTIC_FRAMEWORK_SERVICE_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_oauth_clientId : .*" "predix_oauth_clientId: $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"

    if [[ "$AF_URI" == "" ]]; then
       getAFUri $1
    fi
    if [[ "$AF_ZONE_ID" == "" ]]; then
       getAFZoneId $1
    fi
    __find_and_replace "predix_orchestration_zoneid : .*" "predix_orchestration_zoneid : $AF_ZONE_ID" "manifest.yml" "$logDir"
    AF_HOST=$(echo $AF_URI | awk -F/ '{print $3}')
    echo $AF_HOST
    __find_and_replace "predix_orchestration_restHost : .*" "predix_orchestration_restHost : $AF_HOST" "manifest.yml" "$logDir"

    getUrlForAppName $RMD_ANALYTICS_APP_NAME RMD_ANALYTICS_URL "https"

     echo "Replacing....analytics URL"
     echo $RMD_ANALYTICS_URL
    __find_and_replace "{rmdAnalyticsURI}" "$RMD_ANALYTICS_URL" "manifest.yml" "$logDir"

    cat manifest.yml

    # Push the application
    if [[ $USE_TRAINING_UAA -eq 1 ]]; then
      sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
    fi
    __append_new_head_log "Retrieving the application $RMD_ORCHESTRATION_APP_NAME" "-" "$logDir"
    if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
      mvn clean package -U -B -s $MAVEN_SETTINGS_FILE
    else
      mvn clean dependency:copy -B -s $MAVEN_SETTINGS_FILE
    fi
    __append_new_head_log "Deploying the application $RMD_ORCHESTRATION_APP_NAME" "-" "$logDir"
    if px push; then
      __append_new_line_log "Successfully deployed!" "$logDir"
    else
      __append_new_line_log "Failed to deploy application. Retrying..." "$logDir"
      if px push; then
        __append_new_line_log "Successfully deployed!" "$logDir"
      else
        __error_exit "There was an error pushing using: \"px push\"" "$logDir"
      fi
    fi
    getUrlForAppName $RMD_ORCHESTRATION_APP_NAME APP_URL "https"

    cd ../..
  fi

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
  echo ""  >> $SUMMARY_TEXTFILE
  echo "RMD Orchestration App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed RMD Orchestration to the cloud and updated the manifest file with UAA, Asset and Timeseries info"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$RMD_ORCHESTRATION_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$RMD_ORCHESTRATION_APP_NAME"' to view info about your back-end microservice, and the bound UAA, Asset, and Time Series" >> $SUMMARY_TEXTFILE
  echo "Front-end App URL: https://$FRONT_END_POLYMER_SEED_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo "Front-end App Login: app_user_1/app_user_1" >> $SUMMARY_TEXTFILE
}
