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

COLUMNS=$(tput cols)
run_services=0
run_machine=0
run_frontend=0
run_password=0
run_cleanup=0
run_machine_transfer=0
be_quiet=0

USE_BACKUP_UAA=0
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

#flag handling

#Flag handling
#no argument -> run everything
if (($# == 0)); then
  __append_new_line_log "Will perform default run" "$quickstartLogDir"
  run_services=1
  run_machine=1
  run_frontend=1
  run_cleanup=1
  run_machine_transfer=1
fi

GLOBAL_APPENDER=""
while getopts ":hp:i:smfctbq" opt; do
  case $opt in
    h)
    	__print_out_usage
    	exit
    	;;
    s)
      __append_new_line_log "Services option selected!" "$quickstartLogDir"
      run_services=1
      ;;
    m)
      __append_new_line_log "Machine configuration option selected!" "$quickstartLogDir"
      run_machine=1
      ;;
    f)
      __append_new_line_log "Frontend option selected!" "$quickstartLogDir"
      run_frontend=1
      ;;
    t)
      __append_new_line_log "Machine archive transfer option selected!" "$quickstartLogDir"
      run_machine_transfer=1
      ;;
    b)
      __append_new_line_log "Backup training UAA option selected!" "$quickstartLogDir"
      USE_BACKUP_UAA=1
      ;;
    i)
      if [ ${#OPTARG} -eq 2 ] && [[ "${OPTARG:0:1}" == "-" ]]; then
        echo "Option: \"$opt\" requires a value"
        exit 1
      fi
      GLOBAL_APPENDER=$OPTARG
      ;;
    p)
      run_password=1
      if [ ${#OPTARG} -eq 2 ] && [[ "${OPTARG:0:1}" == "-" ]]; then
        echo "Option: \"$opt\" requires a value"
        exit 1
      fi
      CF_PASSWORD=$OPTARG
    	;;
  	c)
    	__append_new_line_log "Cleanup option selected!" "$quickstartLogDir"
    	run_cleanup=1
    	;;
    q)
      __append_new_line_log "Quiet option selected!" "$quickstartLogDir"
      be_quiet=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

export USE_BACKUP_UAA

#if  [ $run_services -ne 1 ] ; then
#  __append_new_line_log "# Running the script without Services option is not allowed! #" "$quickstartLogDir"
#  exit 1
#fi

#GLOBAL APPENDER
if [[ "$GLOBAL_APPENDER" == "" ]]; then
  echo "Apps and Services in the Predix Cloud need unique names."
  read -p "Enter your global appender, e.g. thomas-edison> " GLOBAL_APPENDER
  while true; do
    if [ "$GLOBAL_APPENDER" == "${GLOBAL_APPENDER/_/}" ]; then
      export GLOBAL_APPENDER
      break;
    else
      echo "Global Appender cannot have underscore(_)."
      read -p "Enter a global appender with dash (-) in place of underscore(_)> " GLOBAL_APPENDER
    fi
  done
fi
export GLOBAL_APPENDER
__append_new_line_log "Using Global Appender : $GLOBAL_APPENDER" "$quickstartLogDir"

CF_HOST="api.system.aws-usw02-pr.ice.predix.io"

source "$quickstartRootDir/scripts/variables.sh"

# Login into Cloud Foundy using the user input or password entered on request

#echo -e "Be sure to set all your variables in the varcf iables.sh file before you run quick start!\n\n"
__append_new_head_log "Checking if you are logged into Cloud Foundry" "-" "$quickstartLogDir"
cf t
# Login into Cloud Foundy using the user input or password entered on request
userSpace="`cf t | grep Space | awk '{print $2}'`"
if [[ "$userSpace" == "" ]] ; then
  if [ $run_password -eq 1 ] ; then
    __append_new_line_log "Using the provided authentication passed to the script..." "$quickstartLogDir"

  else
    read -p "Enter your CF username> " CF_USERNAME
    read -p "Enter your CF password> " -s CF_PASSWORD
  fi

  __append_new_line_log "Attempting to login user \"$CF_USERNAME\" to Cloud Foundry" "$quickstartLogDir"
  if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD --skip-ssl-validation; then
    __append_new_line_log "Successfully logged into CloudFoundry" "$quickstartLogDir"
  else
    __error_exit "There was an error logging into CloudFoundry. Is the password correct?" "$quickstartLogDir"
  fi
fi
if [[ $run_cleanup -eq 1 ]]; then
  ./scripts/cleanup.sh "$TEMP_APP"
fi

# Instantiate, configure, and push the following Predix services: Timeseries, Asset, and UAA.
if [ $run_services -eq 1 ]; then
  ./scripts/predix_services_setup.sh "$TEMP_APP"
fi

# Build our application from the 'predix-nodejs-starter' repo, passing it our MS instances
if [ $run_frontend -eq 1 ]; then
  ./scripts/build-basic-app.sh "$TEMP_APP"
fi

# Build Predix Machine container using properties from Predix Services Created above
if [ $run_machine -eq 1 ] || [ $run_machine_transfer -eq 1 ]; then
  ./scripts/predix_machine_setup.sh "$TEMP_APP" "$run_machine" "$run_machine_transfer"
fi

if [ $be_quiet -eq 0 ]; then
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
