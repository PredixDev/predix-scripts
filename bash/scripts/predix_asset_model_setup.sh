#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to instantiate the following Predix
# services: Timeseries, Asset, and UAA. The script will also configure each service with
# the necessary authorities and scopes, create a UAA user, create UAA client id, and
# post sample data to the Asset service
#

source "$rootDir/bash/scripts/predix_funcs.sh"
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

function getPredixAssetInfo () {
	if [[ "$UAA_URL" == "" ]]; then
		getUaaUrl $1
	fi

	if [[ "$ASSET_URI" == "" ]]; then
		getAssetUri $1
	fi

	# Get the Zone ID from the environment variables (for use when querying Asset data)
	if [[ "$ASSET_ZONE_ID" == "" ]]; then
    getAssetZoneId $1
  fi
}

function assetModelDevice1() {
	__append_new_head_log "Creating Predix Asset Model for Device1" "-" "$logDir"
	ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	ASSET_TAG_NOSPACE=${ASSET_TAG// /_}
	assetPostBody=$(printf "[{\"uri\": \"%s\", \"tag\": \"%s\", \"description\": \"%s\"}]%s" "/$ASSET_TYPE/$ASSET_TAG_NOSPACE" "$ASSET_TAG_NOSPACE" "$ASSET_DESCRIPTION")
	__append_new_line_log "Creating Asset" "$logDir"
	echo "Asset Post Body : $assetPostBody"
	echo "Asset URL : $ASSET_URI"
	createAsset "$UAA_URL" "$UAA_CLIENTID_GENERIC" "$UAA_CLIENTID_GENERIC_SECRET" "$ASSET_URI" "$ASSET_ZONE_ID" "$assetPostBody"
}

function assetModelRMD() {
	__append_new_head_log "Creating Predix Asset Model for RMD" "-" "$logDir"

	getGitRepo "predix-webapp-starter"

	echo "Asset URL : $ASSET_URI"
	CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
	dataExchangeUri=$DATAEXCHANGE_APP_NAME.run.$CLOUD_ENDPONT
	echo $dataExchangeUri
	echo $RUN_CREATE_ASSET_MODEL_RMD_METADATA_FILE
	echo $RUN_CREATE_ASSET_MODEL_RMD_FILE
	createAssetWithMetaData "$UAA_URL" "$UAA_CLIENTID_GENERIC" "$UAA_CLIENTID_GENERIC_SECRET" "$ASSET_URI" "$ASSET_ZONE_ID" "$dataExchangeUri" "$RUN_CREATE_ASSET_MODEL_RMD_METADATA_FILE" "$RUN_CREATE_ASSET_MODEL_RMD_FILE"
}

function __setupAssetModel() {
	if ! [ -d "$logDir" ]; then
		mkdir "$logDir"
		chmod 744 "$logDir"
	fi
	touch "$logDir/quickstart.log"

	# Trap ctrlc and exit if encountered
	trap "trap_ctrlc" 2
	__append_new_head_log "Creating Predix Asset Models" "#" "$logDir"

	__validate_num_arguments 1 $# "\"predix-services-setup.sh\" expected in order: Name of Predix Application used to get VCAP configurations" "$logDir"

	if [[ ( $RUN_CREATE_ASSET_MODEL == 1 ) ]]; then
		getPredixAssetInfo $1

		if [[ ( $RUN_CREATE_ASSET_MODEL_DEVICE1 == 1 ) ]]; then
			assetModelDevice1 $1
		fi

		if [[ ( $RUN_CREATE_ASSET_MODEL_RMD == 1 ) ]]; then
			assetModelRMD $1
		fi
	fi


	__append_new_line_log "Predix Services Configurations found in file: \"$SUMMARY_TEXTFILE\"" "$logDir"

	echo ""  >> $SUMMARY_TEXTFILE
	echo "Predix Services Configuration"  >> $SUMMARY_TEXTFILE
	echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
	echo ""  >> $SUMMARY_TEXTFILE
	echo "Installed UAA with a client_id/secret (for your app) and a user/password (for your users to log in to your app)" >> $SUMMARY_TEXTFILE
	echo "Installed Time Series and added time series scopes as client_id authorities" >> $SUMMARY_TEXTFILE
	echo "Installed Asset and added asset scopes as client_id authorities" >> $SUMMARY_TEXTFILE
	echo "" >> $SUMMARY_TEXTFILE
	echo "UAA URL: $UAA_URL" >> $SUMMARY_TEXTFILE
	echo "UAA Admin Client ID: admin" >> $SUMMARY_TEXTFILE
	echo "UAA Admin Client Secret: $UAA_ADMIN_SECRET" >> $SUMMARY_TEXTFILE
	echo "UAA Generic Client ID: $UAA_CLIENTID_GENERIC" >> $SUMMARY_TEXTFILE
	echo "UAA Generic Client Secret: $UAA_CLIENTID_GENERIC_SECRET" >> $SUMMARY_TEXTFILE
	echo "UAA User ID: $UAA_USER_NAME" >> $SUMMARY_TEXTFILE
	echo "UAA User PASSWORD: $UAA_USER_PASSWORD" >> $SUMMARY_TEXTFILE
	echo "TimeSeries Ingest URL:  $TIMESERIES_INGEST_URI" >> $SUMMARY_TEXTFILE
	echo "TimeSeries Query URL:  $TIMESERIES_QUERY_URI" >> $SUMMARY_TEXTFILE
	echo "TimeSeries ZoneID: $TIMESERIES_ZONE_ID" >> $SUMMARY_TEXTFILE
	echo "Asset URL:  $ASSET_URI" >> $SUMMARY_TEXTFILE
	echo "Asset Zone ID: $ASSET_ZONE_ID" >> $SUMMARY_TEXTFILE
}
