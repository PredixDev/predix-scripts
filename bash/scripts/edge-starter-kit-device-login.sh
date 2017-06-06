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
function edge-starter-kit-device-login-main() {
  __validate_num_arguments 1 $# "\"edge-starter-kit-device-login.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"
  __append_new_head_log "Log in to the device" "-" "$logDir"
  TARGETDEVICEIP=""
	TARGETDEVICEUSER=""
	read -p "Enter the IP Address of your device(press enter if you are already on the device)> " TARGETDEVICEIP
	TARGETDEVICEIP=${TARGETDEVICEIP:localhost}
	if [ "$TARGETDEVICEIP" != "" ] && [ "$TARGETDEVICEIP" != "localhost" ]; then
		read -p "Enter the Username on your device[$EDGE_DEVICE_KIT_USER]> " TARGETDEVICEUSER
    if [[ $TARGETDEVICEUSER == "" ]]; then
      TARGETDEVICEUSER=$EDGE_DEVICE_KIT_USER
    fi

    echo "Once you ssh in to the device, you are running in the context of the Predix Dev Kit."
    echo "Any network, proxy, permissions or other errors should be investigated relative to the device, not your personal computer."
    echo "Logged in to device with username=$TARGETDEVICEUSER@TARGETDEVICEIP" >> "$SUMMARY_TEXTFILE"

    __echo_run ssh $TARGETDEVICEUSER@$TARGETDEVICEIP 'pwd; rm -rf kit-cloud/predix-scripts; export DYLD_INSERT_LIBRARIES=; bash -l <( curl https://raw.githubusercontent.com/PredixDev/kit-cloud-app/'"$BRANCH"'/scripts/quickstart-kit-cloud-app.sh) -o -kitpca --skip-setup -i' $INSTANCE_PREPENDER
    pwd
  else
    source "$rootDir/bash/scripts/edge-starter-kit-device-personal.sh"
    edge-starter-kit-device-personal-main $1
  fi

  echo "" >> $SUMMARY_TEXTFILE
}
