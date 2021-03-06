#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"


# Reset all variables that might be set
RUN_CREATE_DEVICE=0
RUN_UPLOAD_APPLICATION=0
RUN_UPLOAD_CONFIGIURATION=0

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
                ;;
			-ed|--enroll-device)
				RUN_START_ENROLLMENT=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-enroll-device|--enroll-device"
				SWITCH_ARRAY[SWITCH_INDEX++]="-ed"
        PRINT_USAGE=0
				;;
			-em-device-id|--em-device-id)
        DEVICE_ID="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-id|--em-device-id"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-id"
        PRINT_USAGE=0
        ;;
			-em-device-secret|--em-device-secret)
        DEVICE_SECRET="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-secret|--em-device-secret"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-secret"
        PRINT_USAGE=0
        ;;
			-em-device-ip-address|--em-device-ip-address)
        DEVICE_IP_ADDRESS="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-ip-address|--em-device-ip-address"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-ip-address"
        PRINT_USAGE=0
        ;;
			-em-device-login-user|--em-device-login-user)
        DEVICE_LOGIN_USER="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-login-user|--em-device-login-user"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-login-user"
        PRINT_USAGE=0
        ;;
			-em-device-login-password|--em-device-login-password)
        DEVICE_LOGIN_PASSWORD="$2"
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-device-login-pass|--em-device-login-password"
 				SWITCH_ARRAY[SWITCH_INDEX++]="-em-device-login-password"
        PRINT_USAGE=0
        ;;
			-cp|--create-packages)
				RUN_CREATE_PACKAGES=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cp|--create-packages"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cp"
				PRINT_USAGE=0
				;;
			-ca|--upload-application)
				RUN_UPLOAD_APPLICATION=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-ca|--upload-application"
				SWITCH_ARRAY[SWITCH_INDEX++]="-ca"
				PRINT_USAGE=0
				;;
			-cc|--upload-configuration)
			  RUN_UPLOAD_CONFIGIURATION=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-cc|--upload-configuration"
				SWITCH_ARRAY[SWITCH_INDEX++]="-cc"
			  PRINT_USAGE=0
			  ;;
			-em-tenant-id|--em-tenant-id)
				EM_TENANT_ID="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-id|--em-tenant-id"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-id"
			  PRINT_USAGE=0
				;;
			-em-uaa-zone-id|--em-uaa-zone-id)
				EM_UAA_ZONE_ID="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-uaa-zone-id|--em-uaa-zone-id"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-uaa-zone-id"
			  PRINT_USAGE=0
				;;
			-em-tenant-admin-user|--em-tenant-admin-user)
				EM_USER_ID="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-admin-user|--em-tenant-admin-user"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-admin-user"
			  PRINT_USAGE=0
				;;
			-em-tenant-admin-password|--em-tenant-admin-password)
				EM_USER_PASSWORD="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-admin-password|--em-tenant-admin-password"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-admin-password"
			  PRINT_USAGE=0
				;;
			-em-tenant-client-id|--em-tenant-client-id)
				EM_CLIENT_ID="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-client-id|--em-tenant-client-id"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-client-id"
			  PRINT_USAGE=0
				;;
			-em-tenant-client-secret|--em-tenant-client-secret)
				EM_CLIENT_SECRET="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-em-tenant-client-secret|--em-tenant-client-secret"
				SWITCH_ARRAY[SWITCH_INDEX++]="-em-tenant-client-secret"
			  PRINT_USAGE=0
				;;
			-edge-app-name|--edge-app-name)
				EDGE_APP_NAME="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-edge-app-name|--edge-app-name"
				SWITCH_ARRAY[SWITCH_INDEX++]="-edge-app-name"
				PRINT_USAGE=0
				;;
			-asset-name|--asset-name)
				ASSET_NAME="$2"
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-asset-name|--asset-name"
				SWITCH_ARRAY[SWITCH_INDEX++]="-asset-name"
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
	echo "PREDIX SERVICES"
	echo "  SKIP_PREDIX_SERVICES        : $SKIP_PREDIX_SERVICES"
	echo "  LOGIN                       : $LOGIN"
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
	echo "    DEVICE_IP_ADDRESS         :	$DEVICE_IP_ADDRESS"
	echo "    DEVICE_LOGIN_USER         :	$DEVICE_LOGIN_USER"
	echo "    DEVICE_LOGIN_PASSWORD     :	$DEVICE_LOGIN_PASSWORD"
	echo "  PACKAGE CONFIGURATIONS:"
	echo "    RUN_SCHEDULE_PACKAGE      : $RUN_SCHEDULE_PACKAGE"
	echo "    RUN_UPLOAD_APPLICATION    : $RUN_UPLOAD_APPLICATION"
	echo "    RUN_UPLOAD_CONFIGIURATION : $RUN_UPLOAD_CONFIGIURATION"
	echo "    PACKAGE_NAME              : $PACKAGE_NAME"
	echo "    PACKAGE_DESCRIPTION       : $PACKAGE_DESCRIPTION"
	echo "    PACKAGE_VERSION           : $PACKAGE_VERSION"
	echo "  EDGE MMANAGER ENROLLMENT:"
	echo "    RUN_START_ENROLLMENT      : $RUN_START_ENROLLMENT"
	echo " "

	export EDGE_APP_NAME
	export ASSET_NAME
	export EM_TENANT_ID
	export EM_UAA_ZONE_ID
	export EM_CLIENT_ID
	export EM_CLIENT_SECRET
	export EM_USER_ID
	export EM_USER_PASSWORD
	export RUN_CREATE_DEVICE_ID
	export DEVICE_ID
	export DEVICE_SECRET
	export DEVICE_IP_ADDRESS
	export DEVICE_LOGIN_USER
	export DEVICE_LOGIN_PASSWORD
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
					-ca|--upload-application)
					 echo "calling -ca|--upload-application"
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
