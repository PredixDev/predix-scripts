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

function getPredixAssetInfo () {
	__append_new_head_log "Creating Predix Asset Model" "-" "$logDir"
	if [[ "$UAA_URL" == "" ]]; then
		getUaaUrlFromInstance $UAA_INSTANCE_NAME
	fi

	if [[ "$ASSET_URI" == "" ]]; then
		getAssetUriFromInstance $ASSET_INSTANCE_NAME
	fi

	# Get the Zone ID from the environment variables (for use when querying Asset data)
	if [[ "$ASSET_ZONE_ID" == "" ]]; then
    getAssetZoneIdFromInstance $ASSET_INSTANCE_NAME
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
