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
function build-basic-app-polymerseed-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-polymerseed.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Predix UI Polymer Starter which is based on Node.js Starter Front-End Microservice" "-" "$logDir"


  getGitRepo "predix-webapp-starter"
  cd predix-webapp-starter

  #Checkout the tag if provided by user
  #__checkoutTags "$GIT_DIR"

  # Edit the manifest.yml files

  #    Modify the name of the applications
  __find_and_replace "- name: .*" "- name: $FRONT_END_POLYMER_SEED_APP_NAME" "manifest.yml" "$logDir"

  cat manifest.yml

  cat server/localConfig.json

  npm install
  bower install
  gulp dist

  sed '/passport-predix-oauth.git/d' package.json > package1.json
  mv package1.json package.json

  __append_new_head_log "Deploying the application \"$FRONT_END_POLYMER_SEED_APP_NAME\"" "-" "$logDir"
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

  # Automagically open the application in browser, based on OS
  if [[ $SKIP_BROWSER == 0 ]]; then
    apphost=$(cf app $FRONT_END_POLYMER_SEED_APP_NAME | grep urls: | awk '{print $2;}')
    case "$(uname -s)" in
       Darwin)
         # OSX
         open https://$apphost
         ;;

       CYGWIN*|MINGW32*|MINGW64*|MSYS*)
         # Windows
         start "" https://$apphost
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

  if __echo_run cf start $FRONT_END_POLYMER_SEED_APP_NAME; then
    __append_new_line_log "$FRONT_END_POLYMER_SEED_APP_NAME started!" "$logDir" 1>&2
  else
    __error_exit "Couldn't start $FRONT_END_POLYMER_SEED_APP_NAME" "$logDir"
  fi


  CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Predix UI Offline Polymer Starter using JSON data, based on Node.js Express Web App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed a front-end named $FRONT_END_POLYMER_SEED_APP_NAME and updated the property files and manifest.yml" >> $SUMMARY_TEXTFILE
  echo "Setup localconfig.json which is used when developing locally on your laptop" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo "Front-end App URL: https://$FRONT_END_POLYMER_SEED_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo "Front-end App Login: app_user_1/app_user_1" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'cf env "$FRONT_END_POLYMER_SEED_APP_NAME"' to view info about your front-end app" >> $SUMMARY_TEXTFILE
  echo -e "In your web browser, navigate to your front-end application endpoint" >> $SUMMARY_TEXTFILE
}
