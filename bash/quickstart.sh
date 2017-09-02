#!/bin/bash
set -e
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Be sure to set all your variables in the variables.sh file before you run quick start!

#quickstartRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
quickstartRootDir="$( pwd )/predix-scripts"
export quickstartRootDir
cd $quickstartRootDir
quickstartLogDir="$quickstartRootDir/log"
SUMMARY_TEXTFILE="$quickstartLogDir/quickstart-summary.txt"
if [ -f $SUMMARY_TEXTFILE ] ; then
  rm -rf $SUMMARY_TEXTFILE
fi

source "$quickstartRootDir/bash/scripts/error_handling_funcs.sh"
source "$quickstartRootDir/bash/scripts/files_helper_funcs.sh"
source "$quickstartRootDir/bash/scripts/curl_helper_funcs.sh"
source "$quickstartRootDir/bash/scripts/predix_funcs.sh"
source "$quickstartRootDir/bash/common/verifymvn.sh"
source "$rootDir/bash/scripts/local-setup-funcs.sh"

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
  touch "$quickstartLogDir/quickstart.log"
fi

if [ ! -f "$SUMMARY_TEXTFILE" ]; then
  echo "" > $SUMMARY_TEXTFILE
  echo "------------------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "Echoing properties from $SUMMARY_TEXTFILE"  >> $SUMMARY_TEXTFILE
  echo "------------------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo "What did we do:"  >> $SUMMARY_TEXTFILE
fi

export SUMMARY_TEXTFILE

__append_new_head_log "Welcome to the Predix Quickstart script!" "-" "$quickstartLogDir"

__append_new_head_log "Setting the local to en-US for the quickstart script" "-" "$quickstartLogDir"
export PREDIX_NO_CF_BYPASS=false
px config --locale en-US

# Check and install tools
#chmod 755 "$quickstartRootDir/scripts/set_tool.sh"
#"$quickstartRootDir/scripts/set_tool.sh"
source "$quickstartRootDir/bash/readargs.sh"
if [[ ! "$SCRIPT_READARGS" == "" ]]; then
  source "$quickstartRootDir/bash/scripts/$SCRIPT_READARGS"
  processReadargs $@
else
  echo "unable to call SCRIPT_READARGS as nothing is defined"
fi
if [[ ( $LOGIN == 1 ) ]]; then
    #Check px login and target Space
    org="`px target | grep -i Org | awk '{print $2}'`"
    __append_new_line_log "Org : $org" "$quickstartLogDir"
    space="`px target | grep -i Space | awk '{print $2}'`"
    __append_new_line_log "Space : $space" "$quickstartLogDir"
    echo ""

    if [[ "$space" == "" ]] ; then
      read -p "Enter the px API Endpoint (default : https://api.system.aws-usw02-pr.ice.predix.io)> " CF_HOST
      CF_HOST=${CF_HOST:-https://api.system.aws-usw02-pr.ice.predix.io}
      read -p "Enter your px username> " CF_USERNAME
      read -p "Enter your px password> " -s CF_PASSWORD

      __append_new_line_log "Attempting to login user \"$CF_USERNAME\" to Cloud Foundry" "$quickstartLogDir"
      if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD --skip-ssl-validation; then
        __append_new_line_log "Successfully logged into CloudFoundry" "$quickstartLogDir"
      else
        __error_exit "There was an error logging into CloudFoundry. Is the password correct?" "$quickstartLogDir"
      fi
    fi
    ENDPOINT="`px target | grep endpoint | awk '{print $3}'`"

  #UNIQUE Prefix
  if [[ "$INSTANCE_PREPENDER" == "" ]]; then
    __get_login
    echo "Apps and Services in the Predix Cloud need unique names"
    read -p "Enter a unique string to be used as an prefix for service names and app names, e.g. thomas-edison default=[$INSTANCE_PREPENDER]>" INPUT
    INSTANCE_PREPENDER="${INPUT:-$INSTANCE_PREPENDER}"
  fi

  while true; do
    if [ "$INSTANCE_PREPENDER" == "${INSTANCE_PREPENDER/_/}" ]; then
      export INSTANCE_PREPENDER
      break;
    else
      echo "Unique prefix cannot have underscore(_)"
      read -p "Enter a unique prefix with dash (-) in place of underscore(_)> " INSTANCE_PREPENDER
    fi
  done

  __append_new_line_log "Using Unique Prefix : $INSTANCE_PREPENDER" "$quickstartLogDir"

fi

if [[ $VERIFY_MVN == 1 ]]; then
  checkmvnsettings $MAVEN_SETTINGS_FILE
  assertmvn $MAVEN_SETTINGS_FILE
fi
source "$quickstartRootDir/bash/scripts/variables.sh"

#Artifactory settings
if [[ $VERIFY_ARTIFACTORY == 1 ]]; then
  if [[ "$ARTIFACTORY_USERNAME" == "" ]]; then
    fetchArtifactoryKey
  else
    echo "Artifactory user information detected"
  fi
fi

#Note: sourcing subfiles carries variables forward and allows us to have the --continue-from feature
if [[ "$RUN_PRINT_VCAPS" == "1" ]]; then
  source "$quickstartRootDir/bash/scripts/print_service_details.sh"
  __printServiceDetails
  echo "Printed the info from VCAPS : "  >> $SUMMARY_TEXTFILE
fi
# Instantiate, configure, and push the following Predix services: Timeseries, Asset, and UAA.
if [[ ( $RUN_CREATE_SERVICES == 1 || $RUN_CREATE_UAA == 1 || $RUN_CREATE_ASSET == 1 || $RUN_CREATE_MOBILE == 1 ||$RUN_CREATE_TIMESERIES == 1 || $RUN_CREATE_ACS == 1 || $RUN_CREATE_ANALYTIC_FRAMEWORK == 1) ]]; then
  source "$quickstartRootDir/bash/scripts/predix_services_setup.sh"
  __setupServices "$TEMP_APP"
fi

# Build our application
if [[ "$APP_SCRIPT" != "" ]]; then
  source "$quickstartRootDir/bash/scripts/$APP_SCRIPT" "$TEMP_APP"
  main "$TEMP_APP"
fi

function allDone() {
  echo "SUMMARY_TEXTFILE=$SUMMARY_TEXTFILE"
  cat $SUMMARY_TEXTFILE
  echo "Artifactory information username "$ARTIFACTORY_USERNAME " with ApiKey "$ARTIFACTORY_APIKEY
  __append_new_head_log "Clearing the locale" "-" "$quickstartLogDir"
  px config --locale CLEAR
}

if [[ $SKIP_ALL_DONE == 0 ]]; then
  allDone
fi
