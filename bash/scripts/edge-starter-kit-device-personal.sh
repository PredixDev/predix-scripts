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

  __append_new_line_log "hostname is `hostname`" "$logDir"
  __append_new_line_log "current dir is'  `pwd`" "$logDir"

  getUrlForAppName $FRONT_END_KIT_APP_NAME APP_URL "https"
  echo "APP_URL=$APP_URL"

  __find_and_replace "registration_complete = .*" "registration_complete = False" "$PREDIX_KIT_PROPERTY_FILE" "$logDir"
  __find_and_replace "view_in_cloud_url = .*" "view_in_cloud_url = $APP_URL" "$PREDIX_KIT_PROPERTY_FILE" "$logDir"
  __find_and_replace "kit_service_url = .*" "kit_service_url = $APP_URL" "$PREDIX_KIT_PROPERTY_FILE" "$logDir"
  cat $PREDIX_KIT_PROPERTY_FILE

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Put Device in Personal Cloud App mode"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Set new view_in_cloud_url=$APP_URL in $PREDIX_KIT_PROPERTY_FILE" >> $SUMMARY_TEXTFILE
  echo "Set new kit_service_url=$APP_URL in $PREDIX_KIT_PROPERTY_FILE" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
}
