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
__validate_num_arguments 0 $# "\"$0\" expected in order: String of Predix Application used to get VCAP configurations" "$predixMachineLogDir"

	# Get the UAA enviorment variables (VCAPS)
	if trustedIssuerID=$(cf env $TEMP_APP | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$trustedIssuerID" == "" ]] ; then
	    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$predixMachineLogDir"
	  fi
	  __append_new_line_log "Trusted Issuer URL : ${trustedIssuerID}" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting the UAA trustedIssuerID..." "$predixMachineLogDir"
	fi

	if uaaURL=$(cf env $TEMP_APP | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	  if [[ "$uaaURL" == "" ]] ; then
	    __error_exit "The UAA URL was not found for \"$1\"..." "$predixMachineLogDir"
	  fi
	  __append_new_line_log "UAA URL : ${uaaURL}" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting the UAA URL..." "$predixMachineLogDir"
	fi

	if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
		if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
			__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$predixMachineLogDir"
		fi
		__append_new_line_log "Time Series Ingestion URI : ${TIMESERIES_INGEST_URI}" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$predixMachineLogDir"
	fi

	if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
		__append_new_line_log "Time Series Zone Id : ${TIMESERIES_ZONE_ID}" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$predixMachineLogDir"
	fi
	if assetURI=$(cf env $TEMP_APP  | grep uri*| grep predix-asset* | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
		if [[ "$assetURI" == "" ]] ; then
			__error_exit "The Asset URI was not found for \"$1\"..." "$predixMachineLogDir"
		fi
		__append_new_line_log "Asset Service URI : ${assetURI}" "$predixMachineLogDir"
	else
		__error_exit "There was an error getting assetURI..." "$predixMachineLogDir"
	fi
	if ASSET_ZONE_ID=$(cf env $TEMP_APP | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	  if [[ "$ASSET_ZONE_ID" == "" ]] ; then
	    __error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$predixMachineLogDir"
	  fi
		__append_new_line_log "Asset Zone Id : ${ASSET_ZONE_ID}" "$predixMachineLogDir"
	else
	  __error_exit "There was an error getting ASSET_ZONE_ID..." "$predixMachineLogDir"
	fi


	echo ""
