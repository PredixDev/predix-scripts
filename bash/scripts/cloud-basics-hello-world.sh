#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

currentDir="$( pwd )"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to instal application specific repos,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"
source "$rootDir/bash/scripts/predix_funcs.sh"

trap "trap_ctrlc" 2

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"
PREDIX_HELLOWORLD_WEBAPP_URL="https://github.com/PredixDev/Predix-HelloWorld-WebApp"
PREDIX_HELLOWORLD_WEBAPP="Predix-HelloWorld-WebApp"

# ********************************** MAIN **********************************
#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function cloud-basics-hello-world-main() {
  __validate_num_arguments 0 $# "\"cloud-basics.sh\" expected in order: none" "$logDir"

  __append_new_head_log "Build & Deploy Application" "#" "$logDir"

  echo ""
  echo "Step 1. Download the Predix Hello World web application"
  echo "--------------------------------------------------------------"
  answer="y"

  if [ -d $PREDIX_HELLOWORLD_WEBAPP ]; then
    echo "The $PREDIX_HELLOWORLD_WEBAPP already exists."
    read -p "Should we delete it?> " answer
    __verifyAnswer
    echo ""
    if [ "$answer" == "y" ]; then
      rm -rf $PREDIX_HELLOWORLD_WEBAPP
    fi
  fi
  if [ "$answer" == "y" ]; then
    __echoAndRun git clone --depth 1 --branch $BRANCH $PREDIX_HELLOWORLD_WEBAPP_URL
  fi
  __echoAndRun cd $PREDIX_HELLOWORLD_WEBAPP

  echo ""
  echo "Step 3. Give the application a unique name"
  echo "--------------------------------------------------------------"
  echo "We will give the application a unique name by editing the manifest file (manifest.yml)."
  echo "This file contains all the information about the application."
  echo ""

  app_name=$PREDIX_HELLOWORLD_WEBAPP-$INSTANCE_PREPENDER
  sed -i -e "s/name: .*$PREDIX_HELLOWORLD_WEBAPP.*$/name: $app_name/" manifest.yml
  echo "Application name set to: $app_name"
  echo "This is what the manifest file looks like"
  cat manifest.yml
  echo ""
  echo "Take a moment to study the contents of the manifest file."
  __pause

  echo ""
  echo "Step 4. Push the app to the cloud"
  echo "--------------------------------------------------------------"
  __echoAndRun cf push

  echo ""
  echo "Step 5. Using a browser, visit the URL to see the app"
  echo "--------------------------------------------------------------"
  url=$(cf app Predix-HelloWorld-WebApp-swap-test | grep -i urls | awk '{print $2}')
  echo "You have successfully pushed your first Predix application."
  echo "Enter the URL below in a browser to view the application."
  echo ""
  echo "https://$url"
  echo ""

  echo "We taught you some basics about Predix Cloud orgs, spaces and manifests."  >> "$SUMMARY_TEXTFILE"
  echo "We pulled a repo from git with just 2 files of real interest: index.html and manifest.yml" >> "$SUMMARY_TEXTFILE"
  echo "We then pushed index.html to the cloud using the info in the manifest.yml" >> "$SUMMARY_TEXTFILE"
  echo "" >> "$SUMMARY_TEXTFILE"
  echo "Now you are ready to push a front end microservice and a back end microservice which are the building blocks for your application." >> "$SUMMARY_TEXTFILE"
  echo "" >> "$SUMMARY_TEXTFILE"


}
