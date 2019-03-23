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
source "$quickstartRootDir/bash/scripts/local-setup-funcs.sh"
source "$quickstartRootDir/bash/docker/docker_functions.sh"
#source "$quickstartRootDir/bash/common/proxy/verify-proxy.sh"

# verifymvn.sh functions have been updated and re-implemented in verify-proxy.sh
# verifymvn.sh is obsolete
#source "$quickstartRootDir/bash/common/verifymvn.sh"

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
if [ ! -e DYLD_INSERT_LIBRARIES ]; then
  export DYLD_INSERT_LIBRARIES=""
fi
px config --locale en-US

# Check and install tools
#chmod 755 "$quickstartRootDir/scripts/set_tool.sh"
#"$quickstartRootDir/scripts/set_tool.sh"
source "$quickstartRootDir/bash/readargs.sh"
if [[ ! "$SCRIPT_READARGS" == "" ]]; then
  source "$quickstartRootDir/bash/scripts/$SCRIPT_READARGS"
  processReadargs $@
  # Curl for Google Analytics
  SCRIPT=`echo "$SCRIPT_NAME" | sed 's|\.||'`
  echo "Curling $REPO_NAME/$SCRIPT for Google Analytics"
  curl -s -H "Cache-Control: no-cache" -L https://predix-beacon.appspot.com/UA-82773213-1/$REPO_NAME/$SCRIPT?pixel
  echo
else
  echo "unable to call SCRIPT_READARGS as nothing is defined"
fi

vercomp () {
  # can't do simple string or numeric comparison for semver string, so we need this function.
  # accepts two semver strings.  i.e. 0.6.3, 1.3.49, etc
  # returns 0 if $1 >= $2, or exits with error.
  # https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            __error_exit "Minimum version of Predix CLI=$PREDIX_CLI_MIN_VALUE is required. Current version is $predixcliversion" "$quickstartLogDir"
        fi
    done
    return 0
}

if [[ $PREDIX_CLI_MIN == 1 ]]; then
  echo
  predixcliversion=`predix --version | cut -d' ' -f3 | cut -d'-' -f3`
  echo "-->> Predix CLI Version : $predixcliversion"
  pxcliversion=`px --version | cut -d' ' -f3 | cut -d'-' -f3`
  echo "-->> PX CLI Link Version : $pxcliversion"
  vercomp $predixcliversion $PREDIX_CLI_MIN_VALUE
fi

if [[ ( $LOGIN == 1 ) ]]; then
    #Check px login and target Space
    if [[ $(px target | grep FAILED | wc -l) -eq "1" ]]; then
      echo "Please login to cloud using 'px login' or 'cf login'.  GE emails will use 'px login --sso' or 'cf login --sso' "
      exit 1
    fi
    org="`px target | grep -i Org | awk '{print $2}'`"
    __append_new_line_log "Org : $org" "$quickstartLogDir"
    space="`px target | grep -i Space | awk '{print $2}'`"
    __append_new_line_log "Space : $space" "$quickstartLogDir"
    echo ""

    if [[ "$space" == "" ]] ; then
      read -p "Enter the Predix API Endpoint (default : https://api.system.aws-usw02-pr.ice.predix.io)> " CF_HOST
      CF_HOST=${CF_HOST:-https://api.system.aws-usw02-pr.ice.predix.io}
      read -p "Enter your Predix username> " CF_USERNAME
      read -p "Enter your Predix password> " -s CF_PASSWORD

      __append_new_line_log "Attempting to login user \"$CF_USERNAME\" to Cloud Foundry" "$quickstartLogDir"
      if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD --skip-ssl-validation; then
        __append_new_line_log "Successfully logged into CloudFoundry" "$quickstartLogDir"
      else
        __error_exit "There was an error logging into CloudFoundry. Is the password correct?  Try logging in manually then rerun script.  For some users your email is tied to SSO login, try cf login -a <api-endpoint> --sso" "$quickstartLogDir"
      fi
    fi
    ENDPOINT="`px target | grep endpoint | awk '{print $3}'`"

  #UNIQUE Prefix
  if [[ "$INSTANCE_PREPENDER" == "" ]]; then
    __get_login
    echo "Apps and Services in the Predix Cloud need unique names"
    read -p "Enter a unique string to be used as an prefix for service names and app names, e.g. thomas-edison default=[$INSTANCE_PREPENDER]>" INPUT
    INSTANCE_PREPENDER="${INPUT:-$INSTANCE_PREPENDER}"
    INSTANCE_PREPENDER=$(echo $INSTANCE_PREPENDER | tr -dc '[:alnum:]\n\r')
  fi

  while true; do
    if [ "$INSTANCE_PREPENDER" == "${INSTANCE_PREPENDER/_/}" ]; then
      export INSTANCE_PREPENDER
      break;
    else
      echo "Unique prefix cannot have underscore(_)"
      read -p "Enter a unique prefix with dash (-) in place of underscore(_)> " INSTANCE_PREPENDER
      INSTANCE_PREPENDER=$(echo $INSTANCE_PREPENDER | tr -dc '[:alnum:]\n\r')
    fi
  done

  __append_new_line_log "Using Unique Prefix : $INSTANCE_PREPENDER" "$quickstartLogDir"

fi

if [[ $VERIFY_MVN == 1 ]]; then
  # Call to new script to verify maven settings
  chmod +x $quickstartRootDir/bash/common/proxy/verify-proxy.sh
  $quickstartRootDir/bash/common/proxy/verify-proxy.sh --maven
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
if [[ ( $RUN_CREATE_UAA == 1 || $RUN_CREATE_ASSET == 1 || $RUN_CREATE_MOBILE == 1 || $RUN_CREATE_TIMESERIES == 1 || $RUN_CREATE_ACS == 1 || $RUN_CREATE_ANALYTIC_FRAMEWORK == 1 || $RUN_CREATE_BLOBSTORE == 1) ]]; then
  source "$quickstartRootDir/bash/scripts/predix_services_setup.sh"
  __setupServices "$TEMP_APP"
fi

# Build our application
echo "$APP_SCRIPT"
if [[ "$APP_SCRIPT" != "" ]]; then
  source "$quickstartRootDir/bash/scripts/$APP_SCRIPT" "$TEMP_APP"
  main "$TEMP_APP"
fi

function allDone() {
  echo "SUMMARY_TEXTFILE=$SUMMARY_TEXTFILE"
  cat $SUMMARY_TEXTFILE
  __append_new_head_log "Clearing the locale" "-" "$quickstartLogDir"
  px config --locale CLEAR
}

if [[ $SKIP_ALL_DONE == 0 ]]; then
  allDone
fi
