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

GIT_DIR="$rootDir/rmd-datasource"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function build-basic-app-rmddatasource-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-rmddatasource.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy RMD Datasource Back-end Microservice" "-" "$logDir"

  # Get the UAA environment variables (VCAPS)
  if [[ "$uaaURL" == "" ]]; then
    getUaaUrlFromInstance $UAA_INSTANCE_NAME
  fi

  cd "$rootDir"
  if [[ "$USE_RMD_DATASOURCE" == "1" ]]; then
    getGitRepo "rmd-datasource"
    cd rmd-datasource

    #Checkout the tag if provided by user
    #__checkoutTags "$GIT_DIR"

    # Edit the manifest.yml files

    #    a) Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $RMD_DATASOURCE_APP_NAME" "manifest.yml" "$logDir"

    #    b) Add the services to bind to the application
    __find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-uaa" "- $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-timeseries" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "- <your-name>-asset" "- $ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"

    #    c) Set the clientid and base64ClientCredentials
    UAA_HOSTNAME=$(echo $uaaURL | awk -F"/" '{print $3}')
    __find_and_replace "predix_uaa_name: .*" "predix_uaa_name: $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{uaaService}" "$UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_timeseries_name : .*" "predix_timeseries_name: $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{timeSeriesService}" "$TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_asset_name : .*" "predix_asset_name: $ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{assetService}" "$ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_oauth_clientId : .*" "predix_oauth_clientId: $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"
    __find_and_replace "{oauthRestHost}" "$UAA_HOSTNAME" "manifest.yml" "$logDir"
    __find_and_replace "{clientId}" "$UAA_CLIENTID_GENERIC" "manifest.yml" "$logDir"
    __find_and_replace "{secret}" "$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"

    cat manifest.yml

    # Push the application
    if [[ $USE_TRAINING_UAA -eq 1 ]]; then
      sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
    fi
    __append_new_head_log "Retrieving the application $RMD_DATASOURCE_APP_NAME" "-" "$logDir"
    if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
      mvn clean package -U -B -s $MAVEN_SETTINGS_FILE
    else
      mvn clean dependency:copy -B -s $MAVEN_SETTINGS_FILE
    fi
    __append_new_head_log "Deploying the application $RMD_DATASOURCE_APP_NAME" "-" "$logDir"
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
    getUrlForAppName $RMD_DATASOURCE_APP_NAME APP_URL "https"

    cd ..
  fi

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Back-end RMD Datasource Spring Boot Microservice App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed RMD Datasource back-end microservice to the cloud and updated the manifest file with UAA, Asset and Timeseries info"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$RMD_DATASOURCE_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$RMD_DATASOURCE_APP_NAME"' to view info about your back-end microservice, and the bound UAA, Asset, and Time Series" >> $SUMMARY_TEXTFILE
}
