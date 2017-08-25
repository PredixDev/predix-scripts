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
    getUrlForAppName $FRONT_END_KIT_APP_NAME APP_URL "https"
    __echo_run ssh -tt -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  $TARGETDEVICEUSER@$TARGETDEVICEIP "pwd; hostname; source /etc/profile; rm -rf kit-cloud; export DYLD_INSERT_LIBRARIES=; curl -s https://raw.githubusercontent.com/PredixDev/kit-cloud-app/$BRANCH/scripts/quickstart-kit-cloud-app.sh | bash /dev/stdin -o -kitpca --skip-setup -b $BRANCH -i $INSTANCE_PREPENDER -kit-app-url $APP_URL"
    pwd
  else
    source "$rootDir/bash/scripts/edge-starter-kit-device-personal.sh"
    edge-starter-kit-device-personal-main $1
  fi

  echo "If the ssh command and script ran well your Personal Cloud App should be ready. If not, you can resolve the error and re-run this script." >> "$SUMMARY_TEXTFILE"
  echo "If the script ran without errors, return to the Device Web App and refresh.  In the Edge To Cloud tab register with your new Personal Cloud App.  Data will be sent to your personal Predix Time Series (charges may incur)." >> "$SUMMARY_TEXTFILE"
  echo "" >> $SUMMARY_TEXTFILE
}
