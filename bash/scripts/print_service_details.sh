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

function __printServiceDetails() {
	if ! [ -d "$logDir" ]; then
		mkdir "$logDir"
		chmod 744 "$logDir"
	fi
	touch "$logDir/quickstartlog.log"

	# Trap ctrlc and exit if encountered

	trap "trap_ctrlc" 2
	__validate_num_arguments 0 $# "\"$0\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

		# Get the UAA enviorment variables (VCAPS)
		if trustedIssuerID=$(px env $TEMP_APP | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
		  if [[ "$trustedIssuerID" == "" ]] ; then
		    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$logDir"
		  fi
		  __append_new_line_log "Trusted Issuer URL : ${trustedIssuerID}" "$logDir"
		else
			__error_exit "There was an error getting the UAA trustedIssuerID..." "$logDir"
		fi

		if uaaURL=$(px env $TEMP_APP | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
		  if [[ "$uaaURL" == "" ]] ; then
		    __error_exit "The UAA URL was not found for \"$1\"..." "$logDir"
		  fi
		  __append_new_line_log "UAA URL : ${uaaURL}" "$logDir"
		else
			__error_exit "There was an error getting the UAA URL..." "$logDir"
		fi

		if TIMESERIES_INGEST_URI=$(px env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
			if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
				__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$logDir"
			fi
			__append_new_line_log "Time Series Ingestion URI : ${TIMESERIES_INGEST_URI}" "$logDir"
		else
			__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$logDir"
		fi

		if TIMESERIES_ZONE_ID=$(px env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
			__append_new_line_log "Time Series Zone Id : ${TIMESERIES_ZONE_ID}" "$logDir"
		else
			__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$logDir"
		fi
		if assetURI=$(px env $TEMP_APP  | grep uri*| grep predix-asset* | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
			if [[ "$assetURI" == "" ]] ; then
				__error_exit "The Asset URI was not found for \"$1\"..." "$logDir"
			fi
			__append_new_line_log "Asset Service URI : ${assetURI}" "$logDir"
		else
			__error_exit "There was an error getting assetURI..." "$logDir"
		fi
		if ASSET_ZONE_ID=$(px env $TEMP_APP | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
		  if [[ "$ASSET_ZONE_ID" == "" ]] ; then
		    __error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$logDir"
		  fi
			__append_new_line_log "Asset Zone Id : ${ASSET_ZONE_ID}" "$logDir"
		else
		  __error_exit "There was an error getting ASSET_ZONE_ID..." "$logDir"
		fi


		echo ""
}
