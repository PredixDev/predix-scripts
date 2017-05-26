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


if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function build-basic-app-websocketserver-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-websocketserver.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy WebSocketServer Back-end Microservice" "-" "$logDir"


  if [[ "$USE_WEBSOCKET_SERVER" == "1" ]]; then
    getGitRepo "predix-websocket-server"
    cd predix-websocket-server

    #Checkout the tag if provided by user
    #__checkoutTags "$GIT_DIR"

    # Edit the manifest.yml files

    #    a) Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $WEBSOCKET_SERVER_APP_NAME" "manifest.yml" "$logDir"

    cat manifest.yml

    # Push the application
    __append_new_head_log "Retrieving the application $WEBSOCKET_SERVER_APP_NAME" "-" "$logDir"
    if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
      mvn clean package -U -s $MAVEN_SETTINGS_FILE
    else
      mvn clean dependency:copy -s $MAVEN_SETTINGS_FILE
    fi
    __append_new_head_log "Deploying the application $WEBSOCKET_SERVER_APP_NAME" "-" "$logDir"
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
    getUrlForAppName $WEBSOCKET_SERVER_APP_NAME APP_URL "https"

    cd ..
  fi

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Back-end Websocket Server Spring Boot Microservice App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed WebSocketServer back-end microservice to the cloud and updated the manifest file"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$WEBSOCKET_SERVER_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$WEBSOCKET_SERVER_APP_NAME"' to view info about your back-end microservice" >> $SUMMARY_TEXTFILE

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  echo "wss all done"
}
