#!/bin/bash
set -e
arguments="$*"
echo "arguments : $arguments"
#if [ -z "$arguments" ]; then
  #__print_out_usage
  #exit
#fi
quickstartRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
quickstartLogDir="$quickstartRootDir/log"

source "$quickstartRootDir/scripts/error_handling_funcs.sh"
source "$quickstartRootDir/scripts/files_helper_funcs.sh"
source "$quickstartRootDir/scripts/curl_helper_funcs.sh"

if ! [ -d "$quickstartLogDir" ]; then
  mkdir "$quickstartLogDir"
  chmod 744 "$quickstartLogDir"
  touch "$quickstartLogDir/quickstartlog.log"
fi

# Reset all variables that might be set

USE_TRAINING_UAA=0
CUSTOM_UAA_INSTANCE=""
RUN_DELETE_SERVICES=0
RUN_CREATE_SERVICES=0
RUN_MACHINE_CONFIG=0
RUN_COMPILE_REPO=0
RUN_MACHINE_TRANSFER=0
RUN_DEPLOY_FRONTEND=0
RUN_PRINT_VCAPS=0
SKIP_SERVICES=0
BRANCH="master"
RUN_CREATE_MACHINE_CONTAINER=0
QUIET_MODE=0
USE_WINDDATA_SERVICE=1
VERIFY_MVN=1
MACHINE_CONTAINER_TYPE="Debug"
verbose=0 # Variables to be evaluated as shell arithmetic should be initialized to a default or validated beforehand.
###################### Read Global Appender and Predix Scripts Branch
while :; do
    case $1 in
        -h|-\?|--help)   # Call a "__print_out_usage" function to display a synopsis, then exit.
          __print_out_usage
          exit
          ;;
        -i|--instance-appender)       # Takes an option argument, ensuring it has been specified.
          if [ -n "$2" ]; then
              INSTANCE_PREPENDER=$(echo $2 | tr 'A-Z' 'a-z')
              shift
          else
              printf 'ERROR: "-i or --instance-appender" requires a non-empty option argument.\n' >&2
              exit 1
          fi
          ;;
        -all)
          RUN_CREATE_SERVICES=1
          RUN_MACHINE_CONFIG=1
          RUN_COMPILE_REPO=1
          RUN_MACHINE_TRANSFER=1
          RUN_DEPLOY_FRONTEND=1
          ;;
        -tu|--training-uaa)
          USE_TRAINING_UAA=1
          ;;
        -custom-uaa)
          if [ -n "$2" ]; then
              CUSTOM_UAA_INSTANCE=$2
              shift
          else
              printf 'ERROR: "-custom-uaa" requires a non-empty option argument.\n' >&2
              exit 1
          fi
          ;;
        -ds|--delete-services)
          RUN_DELETE_SERVICES=1
          ;;
        -cs|--create-services)
          RUN_CREATE_SERVICES=1
          ;;
        -mc|--machine-config)
          RUN_MACHINE_CONFIG=1
          ;;
        -cc|--clean-compile)
          RUN_COMPILE_REPO=1
          VERIFY_MVN=1
          ;;
        -mt|--machine-transfer)
          RUN_MACHINE_TRANSFER=1
          ;;
        -if|--install-frontend)
          RUN_DEPLOY_FRONTEND=1
          ;;
        -cm|--create-machine)
          RUN_CREATE_MACHINE_CONTAINER=1
          ;;
        -machine-container-type)
          if [ -n "$2" ]; then
            if [[ $2 =~ ^("Agent"|"Agent_Debug"|"Prov"|"Debug"|"Tech"|"Conn"|"Custom"|"AGENT"|"AGENT_DEBUG"|"PROV"|"DEBUG"|"TECH"|"CONN"|"CUSTOM")$ ]]; then
              MACHINE_CONTAINER_TYPE=$2
            else
              printf 'ERROR: "machine-container-type" requires a argument[AGENT|AGENT_DEBUG|PROV|DEBUG|TECH|CONN|CUSTOM].\n' >&2
              exit 1
            fi
            shift
          else
            printf 'ERROR: "machine-container-type" requires a argument[AGENT|AGENT_DEBUG|PROV|DEBUG|TECH|CONN|CUSTOM].\n' >&2
            exit 1
          fi
          ;;
        -b|--branch)
          if [ -n "$2" ]; then
            BRANCH=$2
            shift
          else
            printf 'ERROR: "-b or --branch" requires a non-empty option argument.\n' >&2
            exit 1
          fi
          ;;
        -machine-version)
          if [ -n "$2" ]; then
            MACHINE_VERSION=$2
            shift
          else
            printf 'ERROR: "-release| -machine-version" requires a non-empty option argument.\n' >&2
            exit 1
          fi
          ;;
        -em|--edge-manager)
          RUN_EDGE_MANAGER_SETUP=1
          ;;
        -wd|--wind-data)       # Takes an option argument, ensuring it has been specified.
          if [ -n "$2" ]; then
              for i in Yes YES yes y Y;
              do
                if [[ "$2" == "$i" ]]; then
                  USE_WINDDATA_SERVICE=1
                  VERIFY_MVN=1
                else
                  USE_WINDDATA_SERVICE=0
                  VERIFY_MVN=0
                fi
              done;

              shift
          else
              printf 'ERROR: "-wd or --winddata requires a non-empty option argument.\n' >&2
              exit 1
          fi
          ;;
        -q|--quiet-mode)
          QUIET_MODE=1
          ;;
        -v|--verbose)
            verbose=$((verbose + 1)) # Each -v argument adds 1 to verbosity.
            ;;
        -s|--maven-settings)
          if [ -n "$2" ]; then
            MAVEN_SETTNGS_FILE=$2
            shift
          else
            printf 'ERROR: "-s or --maven-settings" requires a non-empty option argument.\n' >&2
            exit 1
          fi
          ;;
        -ss|--skip-services)
          SKIP_SERVICES=1
          ;;
        -p|--print-vcaps)
          RUN_PRINT_VCAPS=1
          ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done
if [[ "$MAVEN_SETTNGS_FILE" == "" ]]; then
  MAVEN_SETTNGS_FILE="$HOME/.m2/settings.xml"
fi
if [[ ($RUN_CREATE_MACHINE_CONTAINER == 1) && (! -n $MACHINE_VERSION) ]]; then
  __error_exit "-cm|--create-machine requires option -machine-version to be set " "$quickstartLogDir"
fi
if [[ ( $RUN_CREATE_MACHINE_CONTAINER == 0 || $RUN_PRINT_VCAPS == 1
  || $RUN_CREATE_SERVICES == 1 || $RUN_MACHINE_CONFIG == 1
  || $RUN_MACHINE_TRANSFER == 1 || $RUN_DEPLOY_FRONTEND == 1  ) ]]; then
  #GLOBAL APPENDER
  if [[ "$INSTANCE_PREPENDER" == "" ]]; then
    echo "Apps and Services in the Predix Cloud need unique names."
    read -p "Enter a unique string to be used as an appender for service names and app names, e.g. thomas-edison> " INSTANCE_PREPENDER
  fi

  while true; do
    if [ "$INSTANCE_PREPENDER" == "${INSTANCE_PREPENDER/_/}" ]; then
      export INSTANCE_PREPENDER
      break;
    else
      echo "Global Appender cannot have underscore(_)."
      read -p "Enter a global appender with dash (-) in place of underscore(_)> " INSTANCE_PREPENDER
    fi
  done

  __append_new_line_log "Using Global Appender : $INSTANCE_PREPENDER" "$quickstartLogDir"

  #Check CF login and target Space
  userSpace="`cf t | grep Space | awk '{print $2}'`"
  __append_new_line_log "userSpace : $userSpace" "$quickstartLogDir"
  echo ""

  if [[ "$userSpace" == "" ]] ; then
    read -p "Enter the CF API Endpoint (default : https://api.system.aws-usw02-pr.ice.predix.io)> " CF_HOST
    CF_HOST=${CF_HOST:-https://api.system.aws-usw02-pr.ice.predix.io}
    read -p "Enter your CF username> " CF_USERNAME
    read -p "Enter your CF password> " -s CF_PASSWORD

    __append_new_line_log "Attempting to login user \"$CF_USERNAME\" to Cloud Foundry" "$quickstartLogDir"
    if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD --skip-ssl-validation; then
      __append_new_line_log "Successfully logged into CloudFoundry" "$quickstartLogDir"
    else
      __error_exit "There was an error logging into CloudFoundry. Is the password correct?" "$quickstartLogDir"
    fi
  fi
fi
MACHINE_VERSION=${MACHINE_VERSION:-16.4.1}
export INSTANCE_PREPENDER
export CUSTOM_UAA_INSTANCE
export USE_TRAINING_UAA
export RUN_DELETE_SERVICES
export RUN_CREATE_SERVICES
export RUN_MACHINE_CONFIG
export RUN_CREATE_MACHINE_CONTAINER
export RUN_COMPILE_REPO
export RUN_EDGE_MANAGER_SETUP
export RUN_MACHINE_TRANSFER
export RUN_DEPLOY_FRONTEND
export BRANCH
export MAVEN_SETTNGS_FILE
export SKIP_SERVICES
export QUIET_MODE
export USE_WINDDATA_SERVICE
export VERIFY_MVN
export MACHINE_CONTAINER_TYPE
export MACHINE_VERSION
if [[ -z "$PRINTED_VARIABLES" && "$RUN_PRINT_VCAPS" == "0" ]]; then
  __append_new_head_log "Global variables available for use" "#" "$quickstartLogDir"
  __append_new_line_log "INSTANCE_PREPENDER" "$quickstartLogDir"
  __append_new_line_log "USE_TRAINING_UAA" "$quickstartLogDir"
  __append_new_line_log "CUSTOM_UAA_INSTANCE" "$quickstartLogDir"
  __append_new_line_log "RUN_DELETE_SERVICES" "$quickstartLogDir"
  __append_new_line_log "RUN_CREATE_SERVICES" "$quickstartLogDir"
  __append_new_line_log "RUN_MACHINE_CONFIG" "$quickstartLogDir"
  __append_new_line_log "RUN_CREATE_MACHINE_CONTAINER" "$quickstartLogDir"
  __append_new_line_log "RUN_EDGE_MANAGER_SETUP" "$quickstartLogDir"
  __append_new_line_log "MACHINE_CONTAINER_TYPE" "$quickstartLogDir"
  __append_new_line_log "RUN_COMPILE_REPO" "$quickstartLogDir"
  __append_new_line_log "RUN_MACHINE_TRANSFER" "$quickstartLogDir"
  __append_new_line_log "RUN_DEPLOY_FRONTEND" "$quickstartLogDir"
  __append_new_line_log "BRANCH" "$quickstartLogDir"
  __append_new_line_log "QUIET_MODE" "$quickstartLogDir"
  __append_new_line_log "MAVEN_SETTNGS_FILE" "$quickstartLogDir"
  __append_new_line_log "SKIP_SERVICES" "$quickstartLogDir"
  __append_new_line_log "USE_WINDDATA_SERVICE" "$quickstartLogDir"
  __append_new_line_log "VERIFY_MVN" "$quickstartLogDir"
  __append_new_line_log "MACHINE_VERSION" "$quickstartLogDir"
  __append_new_head_log "" "" "$quickstartLogDir"
  __append_new_head_log "#" "#" "$quickstartLogDir"

  export PRINTED_VARIABLES="true"
fi
