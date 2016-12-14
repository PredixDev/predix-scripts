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

	echo ""

	PREDIX_MACHINE_HOME="$predixMachineSetupRootDir/../PredixMachine"
	echo $PREDIX_MACHINE_HOME
	if [ "$MACHINE_TEMPLATES_GITHUB_REPO_URL" != "" ]
	then
		echo "Going to $predixMachineSetupRootDir"
		machineTemplatesRepoName="`echo $MACHINE_TEMPLATES_GITHUB_REPO_URL | awk -F"/" '{print $5}' | awk -F"." '{print $1}'`"
		echo "Git URL : $MACHINE_TEMPLATES_GITHUB_REPO_URL"
		echo "Removing $machineTemplatesRepoName"
		rm -rf $machineTemplatesRepoName
		git clone $MACHINE_TEMPLATES_GITHUB_REPO_URL --depth 1

		#Unzip the original PredixMachine container
		rm -rf $PREDIX_MACHINE_HOME
		unzip -oq $machineTemplatesRepoName/PredixMachine.zip -d $PREDIX_MACHINE_HOME

		$predixMachineSetupRootDir/machineconfig.sh "$trustedIssuerID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$uaaURL" "$PREDIX_MACHINE_HOME"
		cp $predixMachineSetupRootDir/pm_background.sh $PREDIX_MACHINE_HOME/machine/bin/predix
		echo "Removing $machineTemplatesRepoName"
		rm -rf $machineTemplatesRepoName
		__append_new_head_log "Created Predix Machine container!" "-" "$predixMachineLogDir"

		echo "" >> $SUMMARY_TEXTFILE
		echo "Edge Device Specific Configuration" >> $SUMMARY_TEXTFILE
		echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
		echo "" >> $SUMMARY_TEXTFILE
		echo "Created Predix Machine container and updated the property files with UAA and Time Series info" >> $PREDIX_SERVICES_TEXTFILE
	fi
fi

if [ "$3" == "1" ]; then
	__append_new_head_log "Transferring Predix Machine Container" "#" "$predixMachineLogDir"
	if type tar >/dev/null; then
		__append_new_line_log "Archiving the configured Predix Machine..." "$predixMachineLogDir"
		rm -f PredixMachineContainer.tar.gz

		if tar -zcf PredixMachineContainer.tar.gz PredixMachine; then
			__append_new_line_log "Archived the configured Predix Machine and stored in PredixMachineContainer.tar.gz" "$predixMachineLogDir"
		else
			__error_exit "Failed to archive PredixMachine" "$predixMachineLogDir"
		fi

		if type scp >/dev/null; then
			TARGETDEVICEIP=""
			TARGETDEVICEUSER=""
			read -p "Enter the IP Address of your device> " TARGETDEVICEIP
			read -p "Enter the Username on your device> " TARGETDEVICEUSER
			echo "scp PredixMachineContainer.tar.gz $TARGETDEVICEUSER@$TARGETDEVICEIP:PredixMachineContainer.tar.gz"
			scp PredixMachineContainer.tar.gz $TARGETDEVICEUSER@$TARGETDEVICEIP:PredixMachineContainer.tar.gz
			__append_new_head_log "Transferred Predix Machine container!" "-" "$predixMachineLogDir"

			echo "We built and deployed the Machine Adapter bundle which reads from the Edison API" >> $SUMMARY_TEXTFILE
		else
			__append_new_line_log "scp not found. You must manually copy PredixMachineContainer.tar.gz to the edge device" "$predixMachineLogDir"
		fi
	else
		__append_new_line_log "tar not found. You must manually archive PredixMachine and port it to the edge device" "$predixMachineLogDir"
	fi
fi
