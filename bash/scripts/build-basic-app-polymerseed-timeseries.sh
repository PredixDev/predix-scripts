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

GIT_DIR="$rootDir/predix-webapp-starter"
BUILD_APP_TEXTFILE="$logDir/build-basic-app-summary.txt"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"

# ********************************** MAIN **********************************
function build-basic-app-polymerseed-timeseries-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-polymerseed.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Predix UI Polymer Starter which is based on Node.js Starter Front-End Microservice" "-" "$logDir"

  MYLOGIN_SECRET=$(echo -ne $UAA_CLIENTID_LOGIN:$UAA_CLIENTID_LOGIN_SECRET | base64)
  MYGENERICS_SECRET=$(echo -ne $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET | base64)

  getGitRepo "predix-webapp-starter"
  cd predix-webapp-starter

  #Checkout the tag if provided by user
  #__checkoutTags "$GIT_DIR"

  # Edit the manifest.yml files

  #    Modify the name of the applications
  __find_and_replace "- name: .*" "- name: $FRONT_END_POLYMER_SEED_APP_NAME" "manifest.yml" "$logDir"

  #    Add the services to bind to the application
  __find_and_replace "\#services:" "services:" "manifest.yml" "$logDir"
  __find_and_append_new_line "services:" "- $UAA_INSTANCE_NAME" "manifest.yml" "$logDir"
  __find_and_append_new_line "services:" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$logDir"

  #    Set the clientid and base64ClientCredentials
  __find_and_replace "\#clientId: .*" "clientId: $UAA_CLIENTID_GENERIC" "manifest.yml" "$logDir"
  __find_and_replace "\#base64ClientCredential: .*" "base64ClientCredential: $MYGENERICS_SECRET" "manifest.yml" "$logDir"
  __find_and_replace "\#loginBase64ClientCredential: .*" "loginBase64ClientCredential: $MYLOGIN_SECRET" "manifest.yml" "$logDir"
  echo "TIMESERIES_CHART_ONLY : $TIMESERIES_CHART_ONLY"
  if [[ "$TIMESERIES_CHART_ONLY" == "true" ]]; then
    __find_and_replace "timeSeriesOnly: .*" "timeSeriesOnly: true" "manifest.yml" "$logDir"
  else
    __find_and_replace "timeSeriesOnly: .*" "timeSeriesOnly: false" "manifest.yml" "$logDir"
  fi

  cat manifest.yml

  # Edit the applications server/localConfig.json file
  __find_and_replace ".*uaaURL\":.*" "    \"uaaURL\": \"$uaaURL\"," "server/localConfig.json" "$logDir"
  __find_and_replace ".*timeseriesZoneId\":.*" "    \"timeseriesZoneId\": \"$TIMESERIES_ZONE_ID\"," "server/localConfig.json" "$logDir"
  __find_and_replace ".*clientId\":.*" "    \"clientId\": \"$UAA_CLIENTID_GENERIC\"," "server/localConfig.json" "$logDir"
  __find_and_replace ".*base64ClientCredential\":.*" "    \"base64ClientCredential\": \"$MYGENERICS_SECRET\"," "server/localConfig.json" "$logDir"
  __find_and_replace "\#loginBase64ClientCredential: .*" "loginBase64ClientCredential: $MYLOGIN_SECRET" "server/localConfig.json" "$logDir"
  __find_and_replace ".*timeseriesURL\":.*" "    \"timeseriesURL\": \"$TIMESERIES_QUERY_URI\"," "server/localConfig.json" "$logDir"

  if [[ "$TIMESERIES_CHART_ONLY" == "true" ]]; then
    __find_and_replace ".*timeSeriesOnly\":.*" "    \"timeSeriesOnly\": \"true\"" "server/localConfig.json" "$logDir"
  else
    __find_and_replace ".*timeSeriesOnly\":.*" "    \"timeSeriesOnly\": \"false\"" "server/localConfig.json" "$logDir"
  fi
  cat server/localConfig.json

  # Push the application
  if [[ $USE_TRAINING_UAA -eq 1 ]]; then
    sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
  fi

  echo "npm install"
  npm install
  echo "bower install"
  bower install
  echo "gulp dist"
  gulp dist


  __append_new_head_log "Deploying the application \"$FRONT_END_POLYMER_SEED_APP_NAME\"" "-" "$logDir"
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
    getUrlForAppName $FRONT_END_POLYMER_SEED_APP_NAME apphost "https"
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

  # Generate the build-basic-app-summary.txt
  cd "$rootDir"
  if [ -f "$BUILD_APP_TEXTFILE" ]
  then
    __append_new_line_log "Deleting existing summary file \"$BUILD_APP_TEXTFILE\"..." "$logDir"
    if rm -f "$BUILD_APP_TEXTFILE"; then
      __append_new_line_log "Successfully deleted!" "$logDir"
    else
      __error_exit "There was an error deleting the file: \"$BUILD_APP_TEXTFILE\"" "$logDir"
    fi
  fi

  if __echo_run px start $FRONT_END_POLYMER_SEED_APP_NAME; then
    __append_new_line_log "$FRONT_END_POLYMER_SEED_APP_NAME started!" "$logDir" 1>&2
  else
    __error_exit "Couldn't start $FRONT_END_POLYMER_SEED_APP_NAME" "$logDir"
  fi


  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Predix UI Polymer Starter based on Node.js Express Web App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed a front-end named $FRONT_END_POLYMER_SEED_APP_NAME and updated the property files and manifest.yml with UAA and Time Series info" >> $SUMMARY_TEXTFILE
  echo "Setup localconfig.json which is used when developing locally on your laptop" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo "Front-end App URL: https://$FRONT_END_POLYMER_SEED_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo "Front-end App Login: app_user_1/App_User_111" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$FRONT_END_POLYMER_SEED_APP_NAME"' to view info about your front-end app, UAA and Time Series" >> $SUMMARY_TEXTFILE
  echo -e "In your web browser, navigate to your front-end application endpoint" >> $SUMMARY_TEXTFILE
}
