#!/bin/bash
set -e
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Be sure to set all your variables in the variables.sh file before you run quick start!

quickstartRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
quickstartLogDir="$quickstartRootDir/log"
SUMMARY_TEXTFILE="$quickstartLogDir/predix-services-summary.txt"

source "$quickstartRootDir/scripts/error_handling_funcs.sh"
source "$quickstartRootDir/scripts/files_helper_funcs.sh"
source "$quickstartRootDir/scripts/curl_helper_funcs.sh"

if [ "${TERM/term}" = "$TERM" ] ; then
  COLUMNS=50
else
  COLUMNS=$(tput cols)
fi

export COLUMNS

# Trap ctrlc and exit if encountered

trap "trap_ctrlc" 2

# Creating a logfile if it doesn't exist
if ! [ -d "$quickstartLogDir" ]; then
  mkdir "$quickstartLogDir"
  chmod 744 "$quickstartLogDir"
  touch "$quickstartLogDir/quickstartlog.log"
fi

if [ ! -f "$SUMMARY_TEXTFILE" ]; then
  echo "" > $SUMMARY_TEXTFILE
  echo "------------------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Echoing properties from $SUMMARY_TEXTFILE"  >> $SUMMARY_TEXTFILE
  echo "Authors SDLP v1 2015" >> $SUMMARY_TEXTFILE
  echo "------------------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "What did we do:"  >> $SUMMARY_TEXTFILE
fi

export SUMMARY_TEXTFILE

__append_new_head_log "Welcome to the Predix quick start script!" "-" "$quickstartLogDir"

# Check and install tools
#chmod 755 $quickstartRootDir/scripts/set_tool.sh
#$quickstartRootDir/scripts/set_tool.sh

source $quickstartRootDir/readargs.sh

echo "INSTANCE_PREPENDER    : $INSTANCE_PREPENDER"
echo "USE_TRAINING_UAA      : $USE_TRAINING_UAA"
echo "RUN_DELETE_SERVICES   : $RUN_DELETE_SERVICES"
echo "RUN_CREATE_SERVICES   : $RUN_CREATE_SERVICES"
echo "RUN_MACHINE_CONFIG    : $RUN_MACHINE_CONFIG"
echo "RUN_COMPILE_REPO      : $RUN_COMPILE_REPO"
echo "RUN_MACHINE_TRANSFER  : $RUN_MACHINE_TRANSFER"
echo "RUN_DEPLOY_FRONTEND   : $RUN_DEPLOY_FRONTEND"
echo "FRONTENDAPP_BRANCH    : $FRONTENDAPP_BRANCH"
echo "QUIET_MODE            : $QUIET_MODE"
echo "MAVEN_SETTNGS_FILE    : $MAVEN_SETTNGS_FILE"

echo $SKIP_CLOUD
if [[ $SKIP_CLOUD -ne 1 ]]; then
    if [[ ( $RUN_CREATE_SERVICES == 0 && $RUN_MACHINE_CONFIG == 0 && $RUN_MACHINE_TRANSFER == 0 && $RUN_DEPLOY_FRONTEND == 0  ) ]]; then
      __print_out_usage
      exit
    fi
    source "$quickstartRootDir/scripts/variables.sh"

    echo "TEMP_APP : $TEMP_APP"
    if [[ $RUN_DELETE_SERVICES -eq 1 ]]; then
      $quickstartRootDir/scripts/cleanup.sh "$TEMP_APP"
    fi

    # Instantiate, configure, and push the following Predix services: Timeseries, Asset, and UAA.
    if [[ $RUN_CREATE_SERVICES -eq 1 ]]; then
      $quickstartRootDir/scripts/predix_services_setup.sh "$TEMP_APP"
    fi

    # Build our application from the 'predix-nodejs-starter' repo, passing it our MS instances
    if [[ $RUN_DEPLOY_FRONTEND -eq 1 ]]; then
      if [ $RUN_DELETE_SERVICES -eq 1 ] && [ $RUN_CREATE_SERVICES -eq 0]; then
        $quickstartRootDir/scripts/predix_services_setup.sh "$TEMP_APP"
      fi
      $quickstartRootDir/scripts/build-basic-app.sh "$TEMP_APP"
    fi
fi

# Build Predix Machine container using properties from Predix Services Created above
if [[ $RUN_MACHINE_CONFIG -eq 1 ]] || [[ $RUN_MACHINE_TRANSFER -eq 1 ]]; then
  $quickstartRootDir/scripts/predix_machine_setup.sh "$TEMP_APP" "$RUN_MACHINE_CONFIG" "$RUN_MACHINE_TRANSFER"
fi

if [[ $QUIET_MODE -eq 0 ]]; then
  cat $SUMMARY_TEXTFILE
fi
# Delete the TEMP APP created earlier
#__append_new_line_log "Deleting the $TEMP_APP" "$quickstartLogDir"
#if cf d $TEMP_APP -f -r; then
#  __append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#else
#  __append_new_line_log "Failed to delete $TEMP_APP. Retrying..." "$quickstartLogDir"
#  if cf d $TEMP_APP -f -r; then
#    __append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#  else
#    __append_new_line_log "Failed to delete $TEMP_APP. Last attempt..." "$quickstartLogDir"
#    if cf d $TEMP_APP -f -r; then
#      __append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartLogDir"
#    else
#      __error_exit "Failed to delete $TEMP_APP. Giving up" "$quickstartLogDir"
#    fi
#  fi
#fi
