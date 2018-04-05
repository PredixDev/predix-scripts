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

GIT_DIR="$rootDir/predix-mobile-starter"
BUILD_APP_TEXTFILE="$logDir/build-basic-app-summary.txt"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"

# ********************************** MAIN **********************************
function build-basic-app-mobilestarter-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-mobilestarter.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Predix Mobile Starter" "-" "$logDir"

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

  #getGitRepo "predix-mobile-starter"
  #cd predix-mobile-starter

  __append_new_line_log "Running pm api $API_GATEWAY_SHORT_ROUTE" "$logDir"
	pm api $API_GATEWAY_SHORT_ROUTE

	__append_new_line_log "Logging in to your Mobile Sync service with pm auth $UAA_USER_NAME $UAA_USER_PASSWORD" "$logDir"
	pm auth $UAA_USER_NAME $UAA_USER_PASSWORD

	cd ..
	__append_new_head_log "Creating mobile workspace" "-" "$logDir"
	mkdir -p mobile_workspace
	cd mobile_workspace
	MOBILE_WORKSPACE="$( pwd )"
	pm workspace --create
  echo "Notice there is now a pm-apps and webapps directory in your mobile-workspace directory.  Each App consists of multiple web-apps."

	__append_new_head_log "Building and publishing webapp" "-" "$logDir"
	cd webapps
	rm -rf MobileExample-WebApp-Sample
	git clone https://github.com/PredixDev/MobileExample-WebApp-Sample.git
	cd MobileExample-WebApp-Sample
	npm install
	npm run build

  __append_new_head_log "Publish WebApp binary to the Mobile Synch Service" "-" "$logDir"
  __append_new_line_log "Notice the webapp.json file, which is referenced by the pm publish command\r " "$logDir"
  cat webapp.json
  echo "pm publish"
	pm publish


	__append_new_head_log "Defining mobile Sample App which registers Web App with Predix Mobile Synch service" "-" "$logDir"
  __append_new_line_log "Creating Mobile Sample App Config - app.json" "$logDir"
	cd ${MOBILE_WORKSPACE}/pm-apps/Sample1

	cat <<EOF > app.json
{
    "name": "Sample1",
    "version": "1.0",
    "starter": "sample-webapp",
    "dependencies": {
        "sample-webapp": "0.0.1"
    }
}
EOF
  cat app.json
  echo "Note that the dependency name and version need to match what was posted with pm publish in web.json "
  echo ""
  echo "pm define"
	pm define

	__append_new_head_log "Loading Mobile Sample App Data" "-" "$logDir"
	cd ${MOBILE_WORKSPACE}/webapps/MobileExample-WebApp-Sample
	pm import --data ./test/data/data.json --app ../../pm-apps/Sample1/app.json

  cd ${MOBILE_WORKSPACE}/..
  pwd

  echo ""  >> $SUMMARY_TEXTFILE
  echo "Predix Mobile Starter App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Installed a mobile app named $MOBILE_STARTER_APP_NAME and updated the property files and manifest.yml" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
  echo "Mobile App Login: app_user_1/App_User_111" >> $SUMMARY_TEXTFILE
  echo "" >> $SUMMARY_TEXTFILE
}
