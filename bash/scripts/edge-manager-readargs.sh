#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"


# Reset all variables that might be set
RUN_CREATE_DEVICE=0
RUN_CREATE_APPLICATION=0
RUN_CREATE_CONFIGIURATION=0

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
		 -cd|--create-device)
        RUN_CREATE_DEVICE=1
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cd | --create-device"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cd"
        PRINT_USAGE=0
        LOGIN=1
        ;;
			-ed|--enroll-device)
				RUN_START_ENROLLMENT=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-enroll-device|--enroll-device"
				SWITCH_ARRAY[SWITCH_INDEX++]="-ed"
        PRINT_USAGE=0
        LOGIN=1
				;;
			-em-device-id|--em-device-id)
        DEVICE_ID="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-id|--em-device-id"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-id"
        PRINT_USAGE=0
        LOGIN=1
        ;;
			-em-device-secret|--em-device-secret)
        DEVICE_SECRET="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-secret|--em-device-secret"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-secret"
        PRINT_USAGE=0
        LOGIN=1
        ;;
			-cp|--create-packages)
				RUN_CREATE_PACKAGES=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cp|--create-packages"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cp"
				PRINT_USAGE=0
				;;
			-ca|--create-application)
				RUN_CREATE_APPLICATION=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-ca|--create-application"
				SWITCH_ARRAY[SWITCH_INDEX++]="-ca"
				PRINT_USAGE=0
				LOGIN=1
				;;
			-cc|--create-configuration)
			  RUN_CREATE_CONFIGIURATION=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cc|--create-configuration"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cc"
			  PRINT_USAGE=0
			  LOGIN=1
			  ;;
			-em-tenant-id|--em-tenant-id)
				EM_TENANT_ID="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-id|--em-tenant-id"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-id"
			  PRINT_USAGE=0
				;;
			-edge-app-name|--edge-app-name)
				EDGE_APP_NAME="$2"
				echo "1111 : EDGE_APP_NAME : $EDGE_APP_NAME"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-edge-app-name|--edge-app-name"
				SWITCH_ARRAY[SWITCH_INDEX++]="-edge-app-name"
				PRINT_USAGE=0
				;;
			-em-package-name|--em-package-name)
				PACKAGE_NAME="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-package-name|--em-package-name"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-package-name"
			  PRINT_USAGE=0
				;;
			-em-package-desc|--em-package-desc)
				shift;
				PACKAGE_DESCRIPTION="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-package-desc|--em-package-desc"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-package-desc"
			  PRINT_USAGE=0
				;;
			-em-package-version|--em-package-version)
				PACKAGE_VERSION="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-package-version|--em-package-version"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-package-version"
			  PRINT_USAGE=0
				;;
			-em-schedule-package|--em-schedule-package)
				RUN_SCHEDULE_PACKAGE=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-schedule-package|--em-schedule-package"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-schedule-package"
				PRINT_USAGE=0
				LOGIN=1
				;;
			-?*)
				doShift=0
				SUPPRESS_PRINT_UNKNOWN=1
				UNKNOWN_SWITCH=0
				processBuildBasicAppReadargsSwitch $@
				if [[ $UNKNOWN_SWITCH == 1 ]]; then
					echo "unknown Edge Manager switch=$1"
				fi
        ;;
			*)               # Default case: If no more options then break out of the loop.
				;;
  esac
}


function printEdgeStarterVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "1" ]]; then
		printBBAVariables
	fi
	echo "EDGE MANAGER:"
	echo "  EM UAA CONFIGURATIONS"
	echo "    EM_TENANT_ID              : $EM_TENANT_ID"
	echo "    EM_UAA_ZONE_ID            : $EM_UAA_ZONE_ID"
	echo "    EM_CLIENT_ID              : $EM_CLIENT_ID"
	echo "    EM_CLIENT_SECRET          : $EM_CLIENT_SECRET"
	echo "    EM_USER_ID                : $EM_USER_ID"
	echo "    EM_USER_PASSWORD          : $EM_USER_PASSWORD"
	echo "  DEVICE CONFIGURATIONS:"
	echo "    RUN_CREATE_DEVICE_ID      : $RUN_CREATE_DEVICE_ID"
	echo "    DEVICE_ID                 : $DEVICE_ID"
	echo "    DEVICE_SECRET             :	$DEVICE_SECRET"
	echo "  PACKAGE CONFIGURATIONS:"
	echo "    RUN_SCHEDULE_PACKAGE      : $RUN_SCHEDULE_PACKAGE"
	echo "    RUN_CREATE_APPLICATION    : $RUN_CREATE_APPLICATION"
	echo "    RUN_CREATE_CONFIGIURATION : $RUN_CREATE_CONFIGIURATION"
	echo "    PACKAGE_NAME              : $PACKAGE_NAME"
	echo "    PACKAGE_DESCRIPTION       : $PACKAGE_DESCRIPTION"
	echo "    PACKAGE_VERSION           : $PACKAGE_VERSION"
	echo "  EM ENROLLMENT:"
	echo "    RUN_START_ENROLLMENT			: $RUN_START_ENROLLMENT"
	echo "             "

	export EDGE_APP_NAME
	export EM_TENANT_ID
	export EM_UAA_ZONE_ID
	export EM_CLIENT_ID
	export EM_CLIENT_SECRET
	export EM_USER_ID
	export EM_USER_PASSWORD
	export RUN_CREATE_DEVICE_ID
	export DEVICE_ID
	export DEVICE_SECRET
	export PACKAGE_NAME
	export PACKAGE_DESCRIPTION
	export PACKAGE_VERSION
	export RUN_START_ENROLLMENT
	export RUN_SCHEDULE_PACKAGE
}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-cd |      	 --create-device]          					=> Create Device"
	echo -e "./$SCRIPT_NAME                                 => Run all switches"
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
			SUPPRESS_PRINT_UNKNOWN=1
			runFunctionsForBasicApp $1 $2
			case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-cd|--create-device)
					 echo "calling -cd|--create-device"
            createDeviceService $1
            break
            ;;
					-ca|--create-application)
					 echo "calling -ca|--create-application"
            uploadApplicationToEMRepository $1
            break
          	;;
					-da|--deploy-application)
					 echo "calling -da|--deploy-application"
            deployApplicationToDevices $1
            break
            ;;
					-cc|--create-config)
					 echo "calling -cc|--create-config"
            uploadConfigToEMRepository $1
            break
            ;;
					-dc|--deploy-config)
					 echo "calling -dc|--deploy-config"
            deployConfigurationToDevices $1
            break
            ;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
}
