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


function assetModelKit() {
	__append_new_head_log "Creating Predix Asset Model for Kit" "-" "$logDir"

	#getGitRepo "data-exchange"

	echo "Asset URL : $ASSET_URI"
	CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )
	dataExchangeUri=$DATAEXCHANGE_APP_NAME.run.$CLOUD_ENDPONT
	echo $dataExchangeUri
	echo $RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE
	echo $RUN_CREATE_ASSET_MODEL_KIT_FILE
	createAssetWithMetaData "$UAA_URL" "$UAA_CLIENTID_GENERIC" "$UAA_CLIENTID_GENERIC_SECRET" "$ASSET_URI" "$ASSET_ZONE_ID" "$dataExchangeUri" "$RUN_CREATE_ASSET_MODEL_KIT_METADATA_FILE" "$RUN_CREATE_ASSET_MODEL_KIT_FILE"
}
