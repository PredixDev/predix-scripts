#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"

# Reset all variables that might be set
RUN_CREATE_CLIENT_DEVICE_ID=0
USE_KIT_SERVICE=0

#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
while :; do
		#echo "here$@"
		case $1 in
        -cidd|--create-client-id-for-device)
          RUN_CREATE_CLIENT_DEVICE_ID=1
          SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cidd | --create-client-id-for-device"
					SWITCH_ARRAY[SWITCH_INDEX++]="cidd"
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
					break
          ;;
        -?*)
					doShift=0
					processSwitchCommon $@
					if [[ $doShift == 1 ]]; then
						shift
					fi
          ;;
				*)               # Default case: If no more options then break out of the loop.
					echo "default" # End of all options.
          break
					;;
    esac
  	shift
done

#echo "Switches=${SWITCH_DESC_ARRAY[*]}"

if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
	printCommonVariables
  echo "CLIENT CONFIGURATIONS:"
	echo "RUN_CREATE_CLIENT_DEVICE_ID          : $RUN_CREATE_CLIENT_DEVICE_ID"
	echo ""
	echo "SERVICES"
	echo "USE_KIT_SERVICE          : $USE_KIT_SERVICE"
	echo ""
fi

exportCommonVariables
export RUN_CREATE_CLIENT_DEVICE_ID
export USE_KIT_SERVICE

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-ccid|        --create-client-id-for-device]              => Create a client id for Device"
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
function runFunctionForSetUpDevice() {
	while :; do
			runFunctionForCommon $1 $2
	    case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-ccid|--create-rabbitmq)
            createDeviceService $1
            break
            ;;
					-kitsvc|--create-kit-service)
						source "$rootDir/bash/scripts/edge-starter-kit-service.sh"
						device-kit-service-main $1
						break
						;;
		      *)
            echo 'WARN: Unknown function (ignored) in runFunction: %s\n' "$2" >&2
            break
						;;
	    esac
	done
}
