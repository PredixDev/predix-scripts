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
source "$rootDir/bash/scripts/predix_kit_admin_setup.sh"

trap "trap_ctrlc" 2

GIT_DIR="$rootDir/kit-service"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function edge-starter-kit-service-main() {
  __validate_num_arguments 1 $# "\"edge-starter-kit-service.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Kit Microservice" "-" "$logDir"

  UAA_HOSTNAME=$(echo $UAA_URL | awk -F"/" '{print $3}')
  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )

  cd "$rootDir"
  if [[ "$USE_KIT_SERVICE" == "1" ]]; then
    getGitRepo "kit-service"
    cd kit-service

    cd config
    #Setting test user on application.properties file
    __find_and_replace "kit.test.webapp.user=*" "kit.test.webapp.user=$UAA_USER_NAME" "application.properties" "$logDir"
    __find_and_replace "kit.test.webapp.user.password=*" "kit.test.webapp.user.password=$UAA_USER_PASSWORD" "application.properties" "$logDir"
    cd ..

    # Edit the manifest.yml files

    #    a) Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $KIT_SERVICE_APP_NAME" "manifest.yml" "$logDir"

    #    b) Add the services to bind to the application
    __find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
    __find_and_replace "{uaaService}" "$UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{timeSeriesService}" "$TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{assetService}" "$ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"

    #    c) Set the clientid and base64ClientCredentials
    __find_and_replace "predix_uaa_name: .*" "predix_uaa_name: $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{uaaService}" "$UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_timeseries_name : .*" "predix_timeseries_name: $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{timeSeriesService}" "$TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_asset_name : .*" "predix_asset_name: $ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "{assetService}" "$ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
    __find_and_replace "predix_oauth_clientId : .*" "predix_oauth_clientId: $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"
    __find_and_replace "{oauthRestHost}" "$UAA_HOSTNAME" "manifest.yml" "$logDir"
    __find_and_replace "{kitCloudUrl}" "https://$FRONT_END_KIT_APP_NAME.run.$CLOUD_ENDPONT" "manifest.yml" "$logDir"
      MYDEVICE_SECRET=$(echo -ne $UAA_CLIENTID_DEVICE:$UAA_CLIENTID_DEVICE_SECRET | base64)
    __find_and_replace "{deviceEncodedClient}" "$MYDEVICE_SECRET" "manifest.yml" "$logDir"


    cat manifest.yml

    # Push the application
    if [[ $USE_TRAINING_UAA -eq 1 ]]; then
      sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
    fi
    __append_new_head_log "Retrieving the application $KIT_SERVICE_APP_NAME" "-" "$logDir"
    if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
      mvn clean package -U -s $MAVEN_SETTINGS_FILE
    else
      mvn clean dependency:copy -s $MAVEN_SETTINGS_FILE
    fi
    __append_new_head_log "Deploying the application $KIT_SERVICE_APP_NAME" "-" "$logDir"

    # modified for artifactory setup
    if cf push $KIT_SERVICE_APP_NAME --no-start ; then
      __append_new_line_log "Successfully pushed application!" "$logDir"
    else
      __append_new_line_log "Failed to deploy application. Retrying..." "$logDir"
      if cf push $KIT_SERVICE_APP_NAME --no-start ; then
        __append_new_line_log "Successfully pushed application!" "$logDir"
      else
        __error_exit "There was an error pushing using: \"cf push\"" "$logDir"
      fi
    fi
    cf set-env $KIT_SERVICE_APP_NAME ARTIFACTORY_USERNAME $ARTIFACTORY_USERNAME
    cf set-env $KIT_SERVICE_APP_NAME ARTIFACTORY_APIKEY $ARTIFACTORY_APIKEY

    if cf restart $KIT_SERVICE_APP_NAME ; then
      __append_new_line_log "Successfully starting application!" "$logDir"
    else
        __error_exit "There was an error starting deploying using: \"cf restart\"" "$logDir"
    fi

    getUrlForAppName $KIT_SERVICE_APP_NAME APP_URL "https"

    cd ..
  fi

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Back-end Kit Service Spring Boot Microservice App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "InstalledKit Service back-end microservice to the cloud and updated the manifest file with UAA, Asset and Timeseries info"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$KIT_SERVICE_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'cf env "$KIT_SERVICE_APP_NAME"' to view info about your back-end microservice, and the bound UAA, Asset, and Time Series" >> $SUMMARY_TEXTFILE
}
