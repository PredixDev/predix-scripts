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
source "$rootDir/bash/scripts/predix_services_setup.sh"

trap "trap_ctrlc" 2

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"

# ********************************** MAIN **********************************
function edge-starter-kit-ui-main() {
  __validate_num_arguments 1 $# "\"edge-starter-kit-ui.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Predix Kit Cloud App which is based on Polymer Web App Starter Front-End Microservice" "-" "$logDir"

  # Get the environment variables (VCAPS)
  if [[ "$ASSET_URI" == "" ]]; then
    getAssetUri $1
  fi
  if [[ "$TIMESERIES_QUERY_URI" == "" ]]; then
    getTimeseriesQueryUri $1
  fi
  if [[ "$uaaURL" == "" ]]; then
    getUaaUrl $1
  fi
  if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
    getTimeseriesZoneId $1
  fi
  if [[ "$ASSET_ZONE_ID" == "" ]]; then
    getAssetZoneId $1
  fi
  MYLOGIN_SECRET=$(echo -ne $UAA_CLIENTID_LOGIN:$UAA_CLIENTID_LOGIN_SECRET | base64)
  MYGENERICS_SECRET=$(echo -ne $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET | base64)

  getGitRepo "kit-cloud-app"
  cd kit-cloud-app

  # Edit the manifest.yml files

  #    Modify the name of the applications
  __find_and_replace "- name: .*" "- name: $FRONT_END_KIT_APP_NAME" "manifest.yml" "$logDir"
  #    Add the services to bind to the application
  #__find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
  __find_and_append_new_line "services:" " - $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
  __find_and_append_new_line "services:" " - $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"
  __find_and_append_new_line "services:" " - $ASSET_INSTANCE_NAME" "manifest.yml" "$logDir"
  if [[ $RUN_CREATE_CACHE -eq 1 ]]; then
    __find_and_append_new_line "services:" " - $PREDIX_CACHE_INSTANCE_NAME" "manifest.yml" "$logDir"
  fi
  #    Set the clientid and base64ClientCredentials
  #__find_and_replace "\#clientId: .*" "clientId: $UAA_CLIENTID_GENERIC" "manifest.yml" "$logDir"
  __find_and_replace "base64ClientCredential: .*" "base64ClientCredential: $MYGENERICS_SECRET" "manifest.yml" "$logDir"
  __find_and_replace "loginBase64ClientCredential: .*" "loginBase64ClientCredential: $MYLOGIN_SECRET" "manifest.yml" "$logDir"

  getUrlForAppName $KIT_SERVICE_APP_NAME KIT_SERVICE_URL "https"
  __find_and_replace "kitServiceURL:*" "kitServiceURL: $KIT_SERVICE_URL" "manifest.yml" "$logDir"

  cat manifest.yml

  #########
  # Edit the applications server/localConfig.json file
  setJsonProperty ".development.uaaURL" $uaaURL "server/localConfig.json" "$logDir"
  setJsonProperty ".development.timeseriesZoneId" $TIMESERIES_ZONE_ID "server/localConfig.json" "$logDir"
  setJsonProperty ".development.assetZoneId" $ASSET_ZONE_ID "server/localConfig.json" "$logDir"
  setJsonProperty ".development.base64ClientCredential" $MYGENERICS_SECRET "server/localConfig.json" "$logDir"
  setJsonProperty ".development.loginBase64ClientCredential" $MYLOGIN_SECRET "server/localConfig.json" "$logDir"
  # Add the required Timeseries and Asset URIs
  setJsonProperty ".development.assetURL" $ASSET_URI "server/localConfig.json" "$logDir"
  setJsonProperty ".development.timeseriesURL" $TIMESERIES_QUERY_URI "server/localConfig.json" "$logDir"
  setJsonProperty ".development.kitServiceURL" https://$KIT_SERVICE_URL "server/localConfig.json" "$logDir"

  cat server/localConfig.json

  # Push the application
  if [[ $USE_TRAINING_UAA -eq 1 ]]; then
    sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
  fi

  npm install
  bower install
  gulp dist

  sed '/passport-predix-oauth.git/d' package.json > package1.json
  mv package1.json package.json

  __append_new_head_log "Deploying the application \"$FRONT_END_KIT_APP_NAME\"" "-" "$logDir"
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

  # Automagically open the application in browser, based on OS
  if [[ $SKIP_BROWSER == 0 ]]; then
    getUrlForAppName $FRONT_END_KIT_APP_NAME apphost "https"

    case "$(uname -s)" in
       Darwin)
         # OSX
         open $apphost
         ;;

       CYGWIN*|MINGW32*|MINGW64*|MSYS*)
         # Windows
         start "" $apphost
         ;;
    esac
  fi


  if __echo_run px start $FRONT_END_KIT_APP_NAME; then
    __append_new_line_log "$FRONT_END_KIT_APP_NAME started!" "$logDir" 1>&2
  else
    __error_exit "Couldn't start $FRONT_END_KIT_APP_NAME" "$logDir"
  fi

  #return to predix-scripts dir
  cd ..

  CLOUD_ENDPOINT=$(echo $ENDPOINT | cut -d '.' -f3-6 )

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Predix Kit Cloud App based on Predix Polymer Web App Starter"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed a front-end named $FRONT_END_KIT_APP_NAME and updated the property files and manifest.yml with UAA, Time Series and Asset info" >> $SUMMARY_TEXTFILE
  echo "Setup localconfig.json which is used when developing locally on your laptop" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo "Front-end App URL: https://$FRONT_END_KIT_APP_NAME.run.$CLOUD_ENDPOINT" >> $SUMMARY_TEXTFILE
  echo "Shared Front-end App Login: predix.io-username/predix.io-password" >> $SUMMARY_TEXTFILE
  echo "Personal Front-end App Login: app_user_1/app_user_1" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$FRONT_END_KIT_APP_NAME"' to view info about your front-end app, UAA, Asset, and Time Series" >> $SUMMARY_TEXTFILE
  echo -e "In your web browser, navigate to your front-end application endpoint" >> $SUMMARY_TEXTFILE
}
