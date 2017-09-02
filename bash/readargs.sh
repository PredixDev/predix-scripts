#!/bin/bash
set -e
arguments="$*"
echo "arguments : $arguments"

# Reset all variables that might be set
APP_SCRIPT=""
SCRIPT_READARGS=""
RUN_PRINT_VARIABLES=0
BINDING_APP=0
CONTINUE_FROM=0
CONTINUE_FROM_SWITCH=""
RUN_DELETE_SERVICES=0
SWITCH_DESC_INDEX=0
SWITCH_INDEX=0
BRANCH="master"
SKIP_BROWSER=0
SKIP_INTERACTIVE=0
QUIET_MODE=0
VERIFY_MVN=0
PRINT_USAGE=1
PREDIX_CLI_MIN=1
VERIFY_ARTIFACTORY=0
RUN_PRINT_VARIABLES=0
verbose=0 # Variables to be evaluated as shell arithmetic should be initialized to a default or validated beforehand.

if [[ $SKIP_ALL_DONE = "" ]]; then
  SKIP_ALL_DONE=0
fi

#see if they passed in a Continue From argument
arguments=( "$@" )
for ((i = 0; i < ${#arguments[@]}; i++))
do
    switch="${arguments[$i]}"
    case $switch in
      -cf|--continue-from)
        ((i++))
        if [ -n "${arguments[$i]}" ]; then
            CONTINUE_FROM_SWITCH=${arguments[$i]}
            CONTINUE_FROM=1
            PRINT_USAGE=0
        else
            printf 'ERROR: "--continue-from" requires a non-empty "switch to continue from" argument.\n' >&2
            exit 1
        fi
        ;;
      *)               # Default case: If no more options then break out of the loop.
        echo -n "" #do nothing
    esac
done

if [[ ( $CONTINUE_FROM == 1 ) ]]; then
  #shift the args until the continue from switch is reached
  while :; do
    if [[ "$1" =~ ($CONTINUE_FROM_SWITCH) ]]; then
      break;
    else
      shift
    fi
  done
fi

#see if they passed in a script-readargs argument
arguments=( "$@" )
for ((i = 0; i < ${#arguments[@]}; i++))
do
    switch="${arguments[$i]}"
    case $switch in
      -script|--app-script)       # Takes an option argument, ensuring it has been specified.		          -script|--app-script)       # Takes an option argument, ensuring it has been specified.
        if [ -n "${arguments[$i]}" ]; then
          i=$((i+1))
          APP_SCRIPT=${arguments[$i]}
          #SWITCH_ARRAY[SWITCH_INDEX++]="-script | --app-script"
          PRINT_USAGE=0
       else
          printf 'ERROR: "-i or --instance-appender" requires a non-empty option argument.\n' >&2
					exit 1
       fi
       ;;
      -script-readargs)
				i=$((i+1))
        if [ -n "${arguments[$i]}" ]; then
            SCRIPT_READARGS=${arguments[$i]}
            PRINT_USAGE=0
        else
            printf 'ERROR: "--script-readargs" requires a non-empty "switch to readargs from" argument.\n' >&2
            exit 1
        fi
        ;;
	      *)               # Default case: If no more options then break out of the loop.
        echo -n "" #do nothing
    esac
done

function processSwitchCommon() {
	switch="$1"
	case $switch in
		-h|-\?|--help)   # Call a "__print_out_usage" function to display a synopsis, then exit.
			SWITCH_ARRAY[SWITCH_INDEX++]="-h"
			PRINT_HELP=1
			;;
		-b|--branch)
			if [ -n "$2" ]; then
				BRANCH=$2
				shift
				doShift=1
			else
				printf 'ERROR: "-b or --branch" requires a non-empty option argument.\n' >&2
				exit 1
			fi
			;;
		-i|--instance-appender)       # Takes an option argument, ensuring it has been specified.
			if [ -n "$2" ]; then
				INSTANCE_PREPENDER=$(echo $2 | tr 'A-Z' 'a-z')
				shift
				doShift=1
			else
				printf 'ERROR: "-i or --instance-appender" requires a non-empty option argument.\n' >&2
				exit 1
			fi
			;;
    -si|--skip-interactive)
			SKIP_INTERACTIVE=1
		;;
    -sb|--skip-browser)
			SKIP_BROWSER=1
		;;
	-script|--app-script)       # Takes an option argument, ensuring it has been specified.
			shift
			doShift=1
			;;
		-script-readargs)       # Takes an option argument, ensuring it has been specified.
			shift
			doShift=1
			;;
		-ba|--binding-app)
			BINDING_APP=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-ba | --binding-app"
			SWITCH_ARRAY[SWITCH_INDEX++]="-ba"
			PRINT_USAGE=0
			;;
		-cf|--continue-from)
			if [ -n "$2" ]; then
					#not much to do here other than to shift
					PRINT_USAGE=0
					shift
					doShift=1
			else
					printf 'ERROR: "--continue-from" requires a non-empty "switch to continue from" argument.\n' >&2
					exit 1
			fi
			;;
		-ds|--delete-services)
			RUN_DELETE_SERVICES=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-ds | --delete-services"
			PRINT_USAGE=0
			;;
		-q|--quiet-mode)
			QUIET_MODE=1
			;;
		-v|--verbose)
				verbose=$((verbose + 1)) # Each -v argument adds 1 to verbosity.
				;;
		-s|--maven-settings)
			if [ -n "$2" ]; then
				MAVEN_SETTINGS_FILE=$2
				shift
				doShift=1
			else
				printf 'ERROR: "-s or --maven-settings" requires a non-empty option argument.\n' >&2
				exit 1
			fi
			;;
		-ss|--skip-services) #deprecated
			SKIP_SERVICES=1
			;;
		-p|--print-vcaps)
			RUN_PRINT_VARIABLES=1
			LOGIN=1
			;;
    -pxclimin|--predix-cli-min)
  			if [ -n "$2" ]; then
  				PREDIX_CLI_MIN=1
          PREDIX_CLI_MIN_VALUE=$2
  				shift
  				doShift=1
  			else
          printf 'ERROR: "-pxclimin or --predix-cli-min" requires a non-empty option argument.\n' >&2
          exit 1
  			fi
  			;;
    -va|--verify-artifactory)
  			if [ -n "$2" ]; then
  				VERIFY_ARTIFACTORY=1
  				shift
  				doShift=1
  			else
  				printf 'verify-artifactory not set using default' >&2
  			fi
  			;;
		*)               # Default case: If no more options then break out of the loop.
      UNKNOWN_SWITCH=1;
			#break
			;;
	esac

	if [[ "$MAVEN_SETTINGS_FILE" == "" ]]; then
	  MAVEN_SETTINGS_FILE="$HOME/.m2/settings.xml"
	fi
}

function printCommonVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
    echo "  COMMON CONFIGURATIONS:"
	  echo "    quickstartRootDir                        : $quickstartRootDir"
	  echo "    APP_SCRIPT                               : $APP_SCRIPT"
	  echo "    SCRIPT_READARGS                          : $SCRIPT_READARGS"
	  echo "    BINDING_APP                              : $BINDING_APP"
	  echo "    BRANCH                                   : $BRANCH"
	  echo "    CONTINUE_FROM                            : $CONTINUE_FROM"
	  echo "    CONTINUE_FROM_SWITCH                     : $CONTINUE_FROM_SWITCH"
    echo "    LOGIN                                    : $LOGIN"
    echo "    INSTANCE_PREPENDER                       : $INSTANCE_PREPENDER"
    echo "    PREDIX_CLI_MIN                           : $PREDIX_CLI_MIN_VALUE"
	  echo "    QUIET_MODE                               : $QUIET_MODE"
	  echo "    RUN_COMPILE_REPO                         : $RUN_COMPILE_REPO"
	  echo "    RUN_DELETE_SERVICES                      : $RUN_DELETE_SERVICES"
    echo "    SKIP_ALL_DONE                            : $SKIP_ALL_DONE"
    echo "    SKIP_BROWSER                             : $SKIP_BROWSER"
    echo "    SKIP_INTERACTIVE                         : $SKIP_INTERACTIVE"
	  echo ""
	  echo "  BACK-END:"
	  echo "    MAVEN_SETTINGS_FILE                      : $MAVEN_SETTINGS_FILE"
	  echo "    VERIFY_MVN                               : $VERIFY_MVN"
    echo "    VERIFY_ARTIFACTORY                       : $VERIFY_ARTIFACTORY"
	  echo ""
	fi
}

function exportCommonVariables() {
  export BRANCH
  export APP_SCRIPT
	export BINDING_APP
	export CONTINUE_FROM
	export CONTINUE_FROM_SWITCH
  export ENDPOINT
  export INSTANCE_PREPENDER
	export MAVEN_SETTINGS_FILE
  export PREDIX_CLI_MIN
  export QUIET_MODE
	export RUN_DELETE_SERVICES
  export SKIP_BROWSER
  export SKIP_INTERACTIVE
  export SKIP_SERVICES
	export SCRIPT_READARGS
  export SWITCH_DESC_ARRAY
	export VERIFY_MVN
	export VERIFY_ARTIFACTORY
}

function __print_out_common_usage
{
	echo -e "Common Usage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Common options are as below"
  echo "[-b|       --branch]                        => Github Branch, default is master"
  echo "[-ba|      --binding-app]                   => Push an app for binding, to get VCAP"
  echo "[-cc|      --clean-compile]                 => Force clean and compile for java repos"
  echo "[-cf|      --continue-from]                 => Continue quickstart from the switch provided.  e.g. -cf --nodejs-starter"
  echo "[-ds|      --delete-services]               => Delete the service instances previously created"
  echo "[-h|       --help]                          => Print usage"
  echo "[-i|       --instance-prepender]            => Instance appender to identify your service and application instances"
  echo "[-s|       --maven-settings]                => location of mvn settings.xml file, default is ~/.m2/settings.xml"
  echo "[-pxclimin|--predix-cli-min]                => minimum version of predix-cli required"
  echo "[-script|  --app-script]                    => Script that contains application specific behavior"
  echo "[-va|      --verify-artifactory]            => Flag to indicate artifiactory settings for user are required"

	echo -e "*** examples\n"
	echo -e "./$SCRIPT_NAME -cf -switch-to-continue-from => pick up from the provided switch"
}



#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionForCommon() {
    case $2 in
				-h|--help)
					__print_out_common_usage
					;;
				-ba|--binding-app) #ignore
					break
					;;
				-script) #ignore
          break
					;;
		esac
}
