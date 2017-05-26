#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"


# Reset all variables that might be set
RUN_CREATE_CLIENT_DEVICE_ID=0
USE_KIT_SERVICE=0
USE_KIT_UI=0

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
      -cidd|--create-client-id-for-device)
        RUN_CREATE_CLIENT_DEVICE_ID=1
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cidd | --create-client-id-for-device"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cidd"
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
		 -kitui|--create-kit-ui)
        USE_KIT_UI=1
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-kitui | --create-kit-ui"
				SWITCH_ARRAY[SWITCH_INDEX++]="-kitui"
        PRINT_USAGE=0
        LOGIN=1
        ;;
		-amkit|--create-asset-model-kit)
				if [ -n "$2" ]; then
						RUN_CREATE_ASSET_MODEL_KIT=1
						RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE=$2
						SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-amkit | --create-asset-model-kit"
						SWITCH_ARRAY[SWITCH_INDEX++]="-amkit"
						PRINT_USAGE=0
						LOGIN=1
						doShift=1
						shift
						if [ -n "$2" ]; then
							RUN_CREATE_ASSET_MODEL_KIT_FILE=$2
							doShift=2
							shift
						fi
				else
						printf 'ERROR: "-amkit" requires a 2 non-empty option arguments. One for Metadata File, One for AssetModel File\n' >&2
						exit 1
				fi
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
		echo "USE_KIT_UI                               : $USE_KIT_UI"
		echo ""
	  echo "ASSET-MODEL:"
	  echo "RUN_CREATE_ASSET_MODEL_KIT               : $RUN_CREATE_ASSET_MODEL_KIT"
	  echo "RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE : $RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE"
	  echo "RUN_CREATE_ASSET_MODEL_KIT_FILE          : $RUN_CREATE_ASSET_MODEL_KIT_FILE"
		echo ""
	fi

	export RUN_CREATE_CLIENT_DEVICE_ID
	export USE_KIT_SERVICE
	export USE_KIT_UI
	export RUN_CREATE_ASSET_MODEL_KIT
	export RUN_CREATE_ASSET_MODEL_KIT_FILE
	export RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE

}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-cidd|        --create-client-id-for-device]              => Create a client id for Device"
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
					-cidd|--create-client-id-for-device)
					 echo "calling -cidd"
            createDeviceService $1
            break
            ;;
					-kitsvc|--create-kit-service)
						source "$rootDir/bash/scripts/edge-starter-kit-service.sh"
						edge-starter-kit-service-main $1
						break
						;;
					-kitui|--create-kit-ui)
						source "$rootDir/bash/scripts/edge-starter-kit-ui.sh"
						edge-starter-kit-ui-main $1
						break
						;;
					-amkit|--create-asset-model-kit)
						source "$rootDir/bash/scripts/edge-starter-asset-model.sh"
						getPredixAssetInfo $1
						if [[ ( $RUN_CREATE_ASSET_MODEL_KIT == 1 ) ]]; then
							assetModelKit $1
						fi
	          break
						;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
}
