#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"


# Reset all variables that might be set
RUN_CREATE_CLIENT_DEVICE_ID=0
USE_KIT_SERVICE=0

source "$rootDir/bash/scripts/build-basic-app-readargs.sh"


function processReadargs() {
	#process all the switches as normal
	while :; do
			doShift=0
			processEdgeStarterReadargsSwitch $@
			if [[ $doShift == 2 ]]; then
				shift
				shift
			fi
			if [[ $doShift == 1 ]]; then
				shift
			fi
			if [[ $@ == "" ]]; then
				break;
			else
	  			shift
			fi
			#echo "processReadargs $@"
	done
	#echo "Switches=${SWITCH_DESC_ARRAY[*]}"

	printEdgeStarterVariables
}

function processEdgeStarterReadargsSwitch() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	#echo "here$@"
	case $1 in
      -cid|--create-client-id-for-device)
        RUN_CREATE_CLIENT_DEVICE_ID=1
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cid | --create-client-id-for-device"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cid"
        PRINT_USAGE=0
        LOGIN=1
        ;;
			-kitsvc|--create-kit-service)
         USE_KIT_SERVICE=1
         SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-kitsvc | --create-kit-service"
				 SWITCH_ARRAY[SWITCH_INDEX++]="-kitsvc"
         PRINT_USAGE=0
         LOGIN=1
         ;;
      --)
			  # End of all options.
				shift
        ;;
			-?*)
				doShift=0
				SUPPRESS_PRINT_UNKNOWN=1
				UNKNOWN_SWITCH=0
				processBuildBasicAppReadargsSwitch $@
				if [[ $UNKNOWN_SWITCH == 1 ]]; then
					echo "unknown Edge Starter switch=$1"
				fi
        ;;
			*)               # Default case: If no more options then break out of the loop.
				;;
  esac
}


function printEdgeStarterVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
		printBBAVariables
		echo "EDGE STARTER:"
		echo "UAA CONFIGURATIONS:"
		echo "RUN_CREATE_CLIENT_DEVICE_ID              : $RUN_CREATE_CLIENT_DEVICE_ID"
		echo ""
		echo "SERVICES:"
		echo "USE_KIT_SERVICE                          : $USE_KIT_SERVICE"
		echo ""
	fi

	export RUN_CREATE_CLIENT_DEVICE_ID
	export USE_KIT_SERVICE
}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-cid|        --create-client-id-for-device]              => Create a client id for Device"
	echo "[-kitsvc|      --create-kit-service]              => Create a Kit-Service"
	echo -e "*** examples\n"
	echo -e "./$SCRIPT_NAME -ccid                      => Create a client id for Device"
}

#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionsForEdgeStarter() {
	while :; do
			runFunctionsForBasicApp $1 $2
	    case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-cid|--create-client-id-for-device)
					 echo "calling -cid"
            createDeviceService $1
            break
            ;;
					-kitsvc|--create-kit-service)
						source "$rootDir/bash/scripts/edge-starter-kit-service.sh"
						device-kit-service-main $1
						break
						;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
}
