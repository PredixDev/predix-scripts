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
source "$rootDir/bash/scripts/local-setup-funcs.sh"

if ! [ -d "$logDir" ]; then
	mkdir "$logDir"
	chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

#Global variables
echo "PREDIX_MACHINE_HOME : $PREDIX_MACHINE_HOME"
if [[ ( "$PREDIX_MACHINE_HOME" == "") ]]; then
	PREDIX_MACHINE_HOME="$rootDir/PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION"
fi

MACHINE_CONTAINER_ZIP_NAME="PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip"
echo "MACHINE_CONTAINER_ZIP_NAME=$MACHINE_CONTAINER_ZIP_NAME"

# Trap ctrlc and exit if encountered
trap "trap_ctrlc" 2
__validate_num_arguments 3 $# "\"predix-machine-setup.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

if [ "$2" == "1" ]; then
	__append_new_head_log "Creating/Updating Predix Machine Container" "#" "$logDir"
	__append_new_line_log "Reading Predix Machine configuration from VCAP properties" "$logDir"

	# Get the UAA enviorment variables (VCAPS)
	if [[ "$TRUSTED_ISSUER_ID" == "" ]]; then
		getTrustedIssuerId $1
	fi

	if [[ "$TIMESERIES_INGEST_URI" == "" ]]; then
		getTimeseriesIngestUri $1
	fi

	if [[ "$TRUSTED_ZONE_ID" == "" ]]; then
		getTimeseriesZoneId $1
	fi

	#download the predix machine container
	if [[ ! -d "$PREDIX_MACHINE_HOME" ]]; then
		getRepoURL "predix-machine-container-url" MACHINE_CONTAINER_URL ../version.json
		echo "MACHINE_CONTAINER_URL : $MACHINE_CONTAINER_URL"
		if [[ "$MACHINE_CONTAINER_URL" != "" ]]; then
			__echo_run  curl $MACHINE_CONTAINER_URL -o $MACHINE_CONTAINER_ZIP_NAME

			#Unzip the original PredixMachine container
			#rm -rf "$PREDIX_MACHINE_HOME"
			if [[ ! -d "$PREDIX_MACHINE_HOME" ]]; then
				__echo_run unzip $MACHINE_CONTAINER_ZIP_NAME  -d "$PREDIX_MACHINE_HOME"
			fi
		fi
	else
		echo "Warning: PredixMachineHome already exists, did not download and unzip new machine file. $PREDIX_MACHINE_HOME" "$logDir"
	fi

	#update the property files
	$rootDir/bash/scripts/machineconfig.sh "$TRUSTED_ISSUER_ID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$PREDIX_MACHINE_HOME"
	__append_new_head_log "Updated Predix Machine configuration!" "-" "$logDir"

	echo "" >> "$SUMMARY_TEXTFILE"
	echo "Edge Device Specific Configuration" >> "$SUMMARY_TEXTFILE"
	echo "--------------------------------------------------"  >> "$SUMMARY_TEXTFILE"
	echo "" >> "$SUMMARY_TEXTFILE"
	echo "Created/Updated Predix Machine container and updated the property files with UAA and Time Series info" >> "$SUMMARY_TEXTFILE"
	echo "TRUSTED_ISSUER_ID=$TRUSTED_ISSUER_ID" >> "$SUMMARY_TEXTFILE"
	echo "TIMESERIES_INGEST_URI=$TIMESERIES_INGEST_URI" >> "$SUMMARY_TEXTFILE"
	echo "TIMESERIES_ZONE_ID=$TIMESERIES_ZONE_ID" >> "$SUMMARY_TEXTFILE"
fi

cd $rootDir
if [ "$3" == "1" ]; then
	__append_new_head_log "Transferring Predix Machine Container" "#" "$logDir"
	echo "Current Dir is"
	pwd
	rm -rf $MACHINE_CONTAINER_ZIP_NAME
	PREDIX_MACHINE_DIR=$(basename $PREDIX_MACHINE_HOME)
	MACHINE_CONTAINER_TAR_NAME=${MACHINE_CONTAINER_ZIP_NAME%.zip}.tar.gz
	tar -czf $MACHINE_CONTAINER_TAR_NAME $PREDIX_MACHINE_DIR
	if [[ "$RUN_EDGE_MANAGER_SETUP" == "1" ]]; then
		echo "Creating Configuration and Software package"
		pwd
		rm -rf $rootDir/WorkshopSoftware.zip
		rm -rf $rootDir/WorkshopConfiguration.zip
		tar -cvzf -r $rootDir/WorkshopConfiguration.zip configuration
		tar -cvzf -r $rootDir/WorkshopSoftware.zip machine
	fi

	if [[ $SKIP_INTERACTIVE == 0 ]]; then
		if type scp >/dev/null; then
			TARGETDEVICEIP=""
			TARGETDEVICEUSER=""
			read -p "Enter the IP Address of your device(press enter if you want to copy to different directory on the host)> " TARGETDEVICEIP
			TARGETDEVICEIP=${TARGETDEVICEIP:localhost}
			if [ "$TARGETDEVICEIP" != "" ] && [ "$TARGETDEVICEIP" != "localhost" ]; then
				read -p "Enter the Username on your device> " TARGETDEVICEUSER
				echo "scp $MACHINE_CONTAINER_TAR_NAME $TARGETDEVICEUSER@$TARGETDEVICEIP:$MACHINE_CONTAINER_TAR_NAME"
				__echo_run scp $MACHINE_CONTAINER_TAR_NAME $TARGETDEVICEUSER@$TARGETDEVICEIP:$MACHINE_CONTAINER_TAR_NAME
				__append_new_head_log "Transferred Predix Machine container!" "-" "$logDir"
				echo "Copied Machine container zip to the user's home directory on the device" >> "$SUMMARY_TEXTFILE"
				echo "You can backup any existing copy of PredixMachine and tar -xvzf the container" >> "$SUMMARY_TEXTFILE"
			else
				read -p "Enter the location on your local where you want to copy the Machine tar file(Default directory is $HOME/Predix)> " TARGETDIR
				TARGETDIR=${TARGETDIR:-$HOME/Predix}
				echo "Copying Machine container to target directory -> $TARGETDIR"

				if [ ! -e "$TARGETDIR" ]; then
					echo "$TARGETDIR not present. Creating the target directory now"
					mkdir -p "$TARGETDIR"
				fi
				echo "Copied Machine container zip to target directory -> $TARGETDIR" >> "$SUMMARY_TEXTFILE"
				echo "You can backup any existing copy of PredixMachine and tar -xvzf the container at this location -> $TARGETDIR" >> "$SUMMARY_TEXTFILE"
				__echo_run cp $MACHINE_CONTAINER_TAR_NAME $TARGETDIR
			fi
		else
			__append_new_line_log "scp not found. You must manually copy $rootDir/$MACHINE_CONTAINER_TAR_NAME to the edge device" "$logDir"
		fi
	fi
fi
echo "predix_machine_setup.sh : PREDIX_MACHINE_HOME : $PREDIX_MACHINE_HOME"
