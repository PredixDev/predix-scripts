#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to configure a Predix Machine Container
# with the values corresponding to the Predix Services and Predix Application created
#

source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

if ! [ -d "$logDir" ]; then
	mkdir "$logDir"
	chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"
#Global variables
EDGE_MANAGER_HOME="$rootDir/PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION"

# Trap ctrlc and exit if encountered
trap "trap_ctrlc" 2
__validate_num_arguments 3 $# "\"predix-machine-setup.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

if [ "$2" == "1" ]; then
	__append_new_head_log "Creating Predix Machine Container" "#" "$logDir"
	__append_new_line_log "Reading Predix Machine configuration from VCAP properties" "$logDir"

	# Get the UAA enviorment variables (VCAPS)
	if trustedIssuerID=$(px env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$trustedIssuerID" == "" ]] ; then
	    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$logDir"
	  fi
	  __append_new_line_log "trustedIssuerID copied from environmental variables!" "$logDir"
	else
		__error_exit "There was an error getting the UAA trustedIssuerID..." "$logDir"
	fi

	if uaaURL=$(px env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$uaaURL" == "" ]] ; then
	    __error_exit "The UAA URL was not found for \"$1\"..." "$logDir"
	  fi
	  __append_new_line_log "UAA URL copied from environmental variables!" "$logDir"
	else
		__error_exit "There was an error getting the UAA URL..." "$logDir"
	fi

	if TIMESERIES_INGEST_URI=$(px env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
		if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
			__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$logDir"
		fi
		__append_new_line_log "TIMESERIES_INGEST_URI copied from environmental variables!" "$logDir"
	else
		__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$logDir"
	fi

	if TIMESERIES_ZONE_ID=$(px env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
		__append_new_line_log "TIMESERIES_ZONE_ID copied from environmental variables!" "$logDir"
	else
		__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$logDir"
	fi

	if [[ "$RUN_EDGE_MANAGER_SETUP" == "1" ]]; then
		echo "Performing Edge Manager Setup"
		export MACHINE_CONTAINER_TYPE="Prov"
		rm -rf $EDGE_MANAGER_HOME*
		"$rootDir/bash/scripts/create_machine_container.sh"
		unzip PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip -d $EDGE_MANAGER_HOME

		EDGE_DEVICE_SHARED_SECRET=$(python -c "import uuid; print uuid.uuid4();")
		export EDGE_DEVICE_SHARED_SECRET
		__append_new_line_log "EDGE_DEVICE_SHARED_SECRET : $EDGE_DEVICE_SHARED_SECRET" "$logDir"

		echo "export SHARED_SECRET=\"$EDGE_DEVICE_SHARED_SECRET\"" > "$EDGE_MANAGER_HOME/machine/bin/predix/setvars.sh"
		echo "export CAF_SYSTEM_UDI=\"$EDGE_DEVICE_ID\"" >> "$EDGE_MANAGER_HOME/machine/bin/predix/setvars.sh"
		echo "export EDGE_MANAGER_URL=\"$EDGE_MANAGER_URL\"" >> "$EDGE_MANAGER_HOME/machine/bin/predix/setvars.sh"

		cd $EDGE_MANAGER_HOME
		zip -rq ../PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip *
		cd ..

		echo "EDGE_MANAGER_SHARED_CLIENT_SECRET : $EDGE_MANAGER_SHARED_CLIENT_SECRET"
		EDGE_TOKEN=$(curl -X GET -H "Authorization: Basic c2hhcmVkLXRlbmFudC1hcHAtY2xpZW50Okk1NXpLbUFGMFNfQUdkbA==" -H "Cache-Control: no-cache" -H "Content-Type: application/x-www-form-urlencoded" -H "Postman-Token: 38862dbb-f866-1c62-9719-9e1ee8ea2e14" "https://9274a009-9af1-4c5d-a0bb-dfe07771e29c.predix-uaa.run.asv-pr.ice.predix.io/oauth/token?grant_type=client_credentials&client_id=shared-tenant-app-client" | awk -F"\"" '{print $4}')
		echo "EDGE_TOKEN : $EDGE_TOKEN"
		CREATE_DEVICE_RESPONSE=$(curl -X POST -H "Authorization: Bearer $EDGE_TOKEN" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d "[{\"name\":\"$EDGE_DEVICE_NAME\",\"did\":\"$EDGE_DEVICE_ID\",\"modelID\":\"IntelEdison\",\"sharedSecret\":\"$EDGE_DEVICE_SHARED_SECRET\"}]" "https://shared-tenant.edgemanager.run.asv-pr.ice.predix.io/svc/device/v2/device-mgmt/devices/batch" -w "RESP_CODE:%{http_code}")
		echo "CREATE_DEVICE_RESPONSE : $CREATE_DEVICE_RESPONSE"
		RESPONSE_CODE=$(echo $CREATE_DEVICE_RESPONSE | awk -F":" '{print $NF}')
		echo "RESPONSE_CODE: $RESPONSE_CODE"
		if [[ "$RESPONSE_CODE" == "200" ]]; then
			 echo "Device created successfully in Edge Manager"
		fi
	fi

	echo "$PREDIX_MACHINE_HOME"
	getRepoURL "predix-machine-templates" MACHINE_TEMPLATES_GITHUB_REPO_URL ../version.json
	echo "MACHINE_TEMPLATES_GITHUB_REPO_URL : $MACHINE_TEMPLATES_GITHUB_REPO_URL"
	getRepoVersion "predix-machine-templates" MACHINE_TEMPLATES_GITHUB_REPO_VERSION ../version.json
	echo "MACHINE_TEMPLATES_GITHUB_REPO_VERSION : $MACHINE_TEMPLATES_GITHUB_REPO_VERSION"
	machineTemplatesRepoName="`echo $MACHINE_TEMPLATES_GITHUB_REPO_URL | awk -F"/" '{print $5}' | awk -F"." '{print $1}'`"
	echo "machineTemplatesRepoName : $machineTemplatesRepoName"
	if [[ ( "$MACHINE_TEMPLATES_GITHUB_REPO_URL" != ""  && "$MACHINE_TEMPLATES_GITHUB_REPO_VERSION" != "" ) ]]; then
		if [[ ! -d $machineTemplatesRepoName ]]; then
			echo "Git URL : $MACHINE_TEMPLATES_GITHUB_REPO_URL"
			git clone $MACHINE_TEMPLATES_GITHUB_REPO_URL -b $MACHINE_TEMPLATES_GITHUB_REPO_VERSION --depth 1
		fi
		#Unzip the original PredixMachine container
		#rm -rf "$PREDIX_MACHINE_HOME"
		if [[ ! -d "$PREDIX_MACHINE_HOME" ]]; then
			unzip  $machineTemplatesRepoName/PredixMachineDebug.zip -d "$PREDIX_MACHINE_HOME"
		fi
		"$rootDir/bash/scripts/machineconfig.sh" "$trustedIssuerID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$PREDIX_MACHINE_HOME"
		__append_new_head_log "Created Predix Machine container!" "-" "$logDir"

		echo "" >> "$SUMMARY_TEXTFILE"
		echo "Edge Device Specific Configuration" >> "$SUMMARY_TEXTFILE"
		echo "--------------------------------------------------"  >> "$SUMMARY_TEXTFILE"
		echo "" >> "$SUMMARY_TEXTFILE"
		echo "Created Predix Machine container and updated the property files with UAA and Time Series info" >> "$SUMMARY_TEXTFILE"
	fi
fi
cd $rootDir
if [ "$3" == "1" ]; then
	if [[ "$RUN_EDGE_MANAGER_SETUP" == "1" ]]; then
		__append_new_head_log "Transferring Predix Machine Provision Container" "#" "$logDir"
		PREDIX_MACHINE_CONTAINER="PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip"
	else
		__append_new_head_log "Transferring Predix Machine Container" "#" "$logDir"
		PREDIX_MACHINE_CONTAINER="PredixMachineDebug-$MACHINE_VERSION.zip"
	fi
	cd $PREDIX_MACHINE_HOME
	pwd
	if [[ "$RUN_EDGE_MANAGER_SETUP" == "1" ]]; then
		echo "Creating Configuration and Software package"
		pwd
		rm -rf $rootDir/WorkshopSoftware.zip
		rm -rf $rootDir/WorkshopConfiguration.zip
		zip -r $rootDir/WorkshopConfiguration.zip configuration
		zip -r $rootDir/WorkshopSoftware.zip machine
	else
		rm -rf ../PredixMachineDebug-$MACHINE_VERSION.zip
		zip -r ../PredixMachineDebug-$MACHINE_VERSION.zip *
	fi
	cd ..
	pwd
	if type scp >/dev/null; then
		TARGETDEVICEIP=""
		TARGETDEVICEUSER=""
		read -p "Enter the IP Address of your device(press enter if you want to copy to different directory on the host)> " TARGETDEVICEIP
		TARGETDEVICEIP=${TARGETDEVICEIP:localhost}
		if [ "$TARGETDEVICEIP" != "" ] && [ "$TARGETDEVICEIP" != "localhost" ]; then
			read -p "Enter the Username on your device> " TARGETDEVICEUSER
			echo "scp $PREDIX_MACHINE_CONTAINER $TARGETDEVICEUSER@$TARGETDEVICEIP:$PREDIX_MACHINE_CONTAINER"
			scp $PREDIX_MACHINE_CONTAINER $TARGETDEVICEUSER@$TARGETDEVICEIP:$PREDIX_MACHINE_CONTAINER
			__append_new_head_log "Transferred Predix Machine container!" "-" "$logDir"
		else
			read -p "Enter the location on your local where you want to copy the Machine tar file(Default directory is $HOME/Predix)> " TARGETDIR
			TARGETDIR=${TARGETDIR:-$HOME/Predix}
			echo "Copying Machine container to target directory -> $TARGETDIR"

			if [ ! -e "$TARGETDIR" ]; then
				echo "$TARGETDIR not present. Creating the target directory now"
				mkdir -p "$TARGETDIR"
			fi
			cp $PREDIX_MACHINE_CONTAINER $TARGETDIR
		fi
		echo "We built and deployed the Machine Adapter bundle which reads from the Edison API" >> "$SUMMARY_TEXTFILE"
	else
		__append_new_line_log "scp not found. You must manually copy PredixMachineContainer.tar.gz to the edge device" "$logDir"
	fi
fi
echo "predix_machine_setup.sh : PREDIX_MACHINE_HOME : $PREDIX_MACHINE_HOME"
