#!/bin/bash
set -e
predixMachineSetupRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
predixMachineLogDir="$predixMachineSetupRootDir/../log"

PREDIX_SERVICES_TEXTFILE="$predixMachineLogDir/predix-services-summary.txt"
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to configure a Predix Machine Container
# with the values corresponding to the Predix Services and Predix Application created
#

source "$predixMachineSetupRootDir/variables.sh"
source "$predixMachineSetupRootDir/error_handling_funcs.sh"
source "$predixMachineSetupRootDir/files_helper_funcs.sh"
source "$predixMachineSetupRootDir/curl_helper_funcs.sh"

if ! [ -d "$predixMachineLogDir" ]; then
	mkdir "$predixMachineLogDir"
	chmod 744 "$predixMachineLogDir"
fi
touch "$predixMachineLogDir/quickstartlog.log"
#Global variables
PREDIX_MACHINE_HOME="$predixMachineSetupRootDir/../PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION"
MACHINE_CONTAINER_NAME="PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip"
TRANSFER_CONTAINER_NAME="PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.tar"
# Trap ctrlc and exit if encountered
trap "trap_ctrlc" 2
__validate_num_arguments 3 $# "\"predix-machine-setup.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$predixMachineLogDir"

if [ "$2" == "1" ]; then
	__append_new_head_log "Creating Predix Machine Container" "#" "$predixMachineLogDir"
	__append_new_line_log "Reading Predix Machine configuration from VCAP properties" "$predixMachineLogDir"

	# Get the UAA enviorment variables (VCAPS)
	if trustedIssuerID=$(cf env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$trustedIssuerID" == "" ]] ; then
	    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$predixMachineLogDir"
	  fi
	  __append_new_line_log "trustedIssuerID copied from environmental variables!" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting the UAA trustedIssuerID..." "$predixMachineLogDir"
	fi

	if uaaURL=$(cf env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$uaaURL" == "" ]] ; then
	    __error_exit "The UAA URL was not found for \"$1\"..." "$predixMachineLogDir"
	  fi
	  __append_new_line_log "UAA URL copied from environmental variables!" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting the UAA URL..." "$predixMachineLogDir"
	fi

	if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
		if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
			__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$predixMachineLogDir"
		fi
		__append_new_line_log "TIMESERIES_INGEST_URI copied from environmental variables!" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$predixMachineLogDir"
	fi

	if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
		__append_new_line_log "TIMESERIES_ZONE_ID copied from environmental variables!" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$predixMachineLogDir"
	fi

	echo "Predix Machine Home $PREDIX_MACHINE_HOME"
	getRepoURL "predix-machine-templates" MACHINE_TEMPLATES_GITHUB_REPO_URL
	echo "MACHINE_TEMPLATES_GITHUB_REPO_URL : $MACHINE_TEMPLATES_GITHUB_REPO_URL"
	getRepoVersion "predix-machine-templates" MACHINE_TEMPLATES_GITHUB_REPO_VERSION
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
			unzip  $machineTemplatesRepoName/$MACHINE_CONTAINER_NAME -d "$PREDIX_MACHINE_HOME" 
		fi
		"$predixMachineSetupRootDir/machineconfig.sh" "$trustedIssuerID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$uaaURL" "$PREDIX_MACHINE_HOME"
		__append_new_head_log "Created Predix Machine container!" "-" "$predixMachineLogDir"

		echo "" >> "$SUMMARY_TEXTFILE"
		echo "Edge Device Specific Configuration" >> "$SUMMARY_TEXTFILE"
		echo "--------------------------------------------------"  >> "$SUMMARY_TEXTFILE"
		echo "" >> "$SUMMARY_TEXTFILE"
		echo "Created Predix Machine container and updated the property files with UAA and Time Series info" >> "$PREDIX_SERVICES_TEXTFILE"
	fi
fi
cd $predixMachineSetupRootDir/..
if [ "$3" == "1" ]; then

	__append_new_head_log "Transferring Predix Machine Container" "#" "$predixMachineLogDir"
	cd $PREDIX_MACHINE_HOME
	echo "Predix transfer container name : "$TRANSFER_CONTAINER_NAME
	pwd
	rm -rf ../$TRANSFER_CONTAINER_NAME
	ls -l ..
	tar cvfz ../$TRANSFER_CONTAINER_NAME *
	echo "tar complete"
	#zip -r ../$MACHINE_CONTAINER_NAME *
	if [[ "$RUN_EDGE_MANAGER_SETUP" == "1" ]]; then
		echo "Creating Configuration and Software package"
		pwd
		rm -rf $predixMachineSetupRootDir/../WorkshopSoftware.zip
		rm -rf $predixMachineSetupRootDir/../WorkshopConfiguration.zip
		tar cvfz $predixMachineSetupRootDir/../WorkshopConfiguration.zip configuration
		tar cvfz $predixMachineSetupRootDir/../WorkshopSoftware.zip machine
		#zip -r $predixMachineSetupRootDir/../WorkshopConfiguration.zip configuration
		#zip -r $predixMachineSetupRootDir/../WorkshopSoftware.zip machine
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
			echo "scp $TRANSFER_CONTAINER_NAME $TARGETDEVICEUSER@$TARGETDEVICEIP:$TRANSFER_CONTAINER_NAME"
			__echo_run scp $TRANSFER_CONTAINER_NAME $TARGETDEVICEUSER@$TARGETDEVICEIP:$TRANSFER_CONTAINER_NAME
			__append_new_head_log "Transferred Predix Machine container!" "-" "$predixMachineLogDir"
		else
			read -p "Enter the location on your local where you want to copy the Machine tar file(Default directory is $HOME/Predix)> " TARGETDIR
			TARGETDIR=${TARGETDIR:-$HOME/Predix}
			echo "Copying Machine container to target directory -> $TARGETDIR"

			if [ ! -e "$TARGETDIR" ]; then
				echo "$TARGETDIR not present. Creating the target directory now"
				mkdir -p "$TARGETDIR"
			fi
			__echo_run cp $TRANSFER_CONTAINER_NAME $TARGETDIR
		fi
		echo "We built and deployed the Machine Adapter bundle which reads from the Edison API" >> "$PREDIX_SERVICES_TEXTFILE"
	else
		__append_new_line_log "scp not found. You must manually copy PredixMachineContainer.tar.gz to the edge device" "$predixMachineLogDir"
	fi
fi
echo "predix_machine_setup.sh : PREDIX_MACHINE_HOME : $PREDIX_MACHINE_HOME"
