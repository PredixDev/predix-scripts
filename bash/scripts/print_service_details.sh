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

	if [[ "$TRUSTED_ISSUER_ID" == "" ]]; then
	  getTrustedIssuerIdFromInstance $UAA_INSTANCE_NAME
  fi

	if [[ "$UAA_URL" == "" ]]; then
		getUaaUrlFromInstance $UAA_INSTANCE_NAME
	fi

		if [[ "$RUN_CREATE_TIMESERIES" == "1" ]]; then
			if [[ "$TIMESERIES_INGEST_URI" == "" ]]; then
				getTimeseriesIngestUriFromInstance $TIMESERIES_INSTANCE_NAME
			fi

			if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
		    getTimeseriesZoneIdFromInstance $TIMESERIES_INSTANCE_NAME
		  fi
		fi
		if [[ "$RUN_CREATE_ASSET" == "1" ]]; then
			if [[ "$ASSET_URI" == "" ]]; then
		    getAssetUriFromInstance $ASSET_INSTANCE_NAME
		  fi
			if [[ "$ASSET_ZONE_ID" == "" ]]; then
		    getAssetZoneIdFromInstance $ASSET_INSTANCE_NAME
		  fi
		fi

		echo ""
}
