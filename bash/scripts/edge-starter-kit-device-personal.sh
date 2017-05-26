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
function edge-starter-kit-device-personal-main() {
  __validate_num_arguments 1 $# "\"edge-starter-kit-device-personal.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Put Device in Personal Cloud App mode" "-" "$logDir"

  cd /usr/local/bin
  getUrlForAppName $FRONT_END_KIT_APP_NAME APP_URL "https"

  __find_and_replace "VIEW_IN_CLOUD_URL=*" "VIEW_IN_CLOUD_URL=$APP_URL" "$PREDIX_KIT_PROPERTY_FILE" "$logDir"
  __find_and_replace "KIT_SERVICE_URL=*" "KIT_SERVICE_URL=$APP_URL" "$PREDIX_KIT_PROPERTY_FILE" "$logDir"
  cat $PREDIX_KIT_PROPERTY_FILE
  cd $rootDir

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Put Device in Personal Cloud App mode"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Set new VIEW_IN_CLOUD_URL=$APP_URL in $PREDIX_KIT_PROPERTY_FILE" >> $SUMMARY_TEXTFILE
  echo "Set new KIT_SERVICE_URL=$APP_URL in $PREDIX_KIT_PROPERTY_FILE" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
}
