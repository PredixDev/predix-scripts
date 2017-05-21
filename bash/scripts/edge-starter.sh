#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

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

trap "trap_ctrlc" 2

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
__validate_num_arguments 1 $# "\"edge-starter.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

__append_new_head_log "Build & Deploy Kit Service" "#" "$logDir"

#	----------------------------------------------------------------
#	Function called by quickstart.sh, must be spelled main()
#		Accepts 1 arguments:
#			string of app name used to bind to services so we can get VCAP info
#	----------------------------------------------------------------
function main() {
  #execute the build a basic app and switches

  for ((switchIndex = 0; switchIndex < ${#SWITCH_ARRAY[@]}; switchIndex++))
  do
      switch="${SWITCH_ARRAY[$switchIndex]}"
      runFunctionsForEdgeStarter $1 $switch
  done
}
