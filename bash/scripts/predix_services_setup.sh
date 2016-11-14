#!/bin/bash
set -e
predixServicesSetupRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
predixServicesLogDir="$predixServicesSetupRootDir/../log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to instantiate the following Predix
# services: Timeseries, Asset, and UAA. The script will also configure each service with
# the necessary authorities and scopes, create a UAA user, create UAA client id, and
# post sample data to the Asset service
#

source "$predixServicesSetupRootDir/predix_funcs.sh"
source "$predixServicesSetupRootDir/variables.sh"
source "$predixServicesSetupRootDir/error_handling_funcs.sh"
source "$predixServicesSetupRootDir/files_helper_funcs.sh"
source "$predixServicesSetupRootDir/curl_helper_funcs.sh"

if ! [ -d "$predixServicesLogDir" ]; then
	mkdir "$predixServicesLogDir"
	chmod 744 "$predixServicesLogDir"
fi
touch "$predixServicesLogDir/quickstartlog.log"

# Trap ctrlc and exit if encountered
trap "trap_ctrlc" 2
__append_new_head_log "Creating Predix Services" "#" "$predixServicesLogDir"

__validate_num_arguments 1 $# "\"predix-services-setup.sh\" expected in order: Name of Predix Application used to get VCAP configurations" "$predixServicesLogDir"

# Push a test app to get VCAP information for the Predix Services
rm -rf $1
git clone $TEMP_APP_GIT_HUB_URL $1
cd $1
__append_new_line_log "Pushing \"$1\" to initially create Predix Microservices..." "$predixServicesLogDir"
if __echo_run cf push $1 --random-route; then
	__append_new_line_log "App \"$1\" successfully pushed to CloudFoundry!" "$predixServicesLogDir"
else
	if __echo_run cf push $1 --random-route; then
		__append_new_line_log "App \"$1\" successfully pushed to CloudFoundry!" "$predixServicesLogDir"
	else
		__error_exit "There was an error pushing the app \"$1\" to CloudFoundry..." "$predixServicesLogDir"
	fi
fi

# Create instance of Predix UAA Service
__try_create_service $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}" "Predix UAA"

# Bind Temp App to UAA instance
__try_bind $1 $UAA_INSTANCE_NAME

# Get the UAA enviorment variables (VCAPS)
if trustedIssuerID=$(cf env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$trustedIssuerID" == "" ]] ; then
    __error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$predixServicesLogDir"
  fi
  __append_new_line_log "trustedIssuerID copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting the UAA trustedIssuerID..." "$predixServicesLogDir"
fi

if uaaURL=$(cf env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
  if [[ "$uaaURL" == "" ]] ; then
    __error_exit "The UAA URL was not found for \"$1\"..." "$predixServicesLogDir"
  fi
  __append_new_line_log "UAA URL copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting the UAA URL..." "$predixServicesLogDir"
fi


# Create instance of Predix TimeSeries Service
__try_create_service $TIMESERIES_SERVICE_NAME $TIMESERIES_SERVICE_PLAN $TIMESERIES_INSTANCE_NAME "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}" "Predix TimeSeries"

# Bind Temp App to TimeSeries Instance
__try_bind $1 $TIMESERIES_INSTANCE_NAME

# Get the Zone ID and URIs from the environment variables (for use when querying and ingesting data)
if TIMESERIES_ZONE_HEADER_NAME=$(cf env $TEMP_APP | grep -m 100 zone-http-header-name | sed 's/"zone-http-header-name": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "TIMESERIES_ZONE_HEADER_NAME : $TIMESERIES_ZONE_HEADER_NAME"
	__append_new_line_log "TIMESERIES_ZONE_HEADER_NAME copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_HEADER_NAME..." "$predixServicesLogDir"
fi

if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep zone-http-header-value |head -n 1 | awk -F"\"" '{print $4}'); then
	echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
	__append_new_line_log "TIMESERIES_ZONE_ID copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$predixServicesLogDir"
fi

if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
	echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
	__append_new_line_log "TIMESERIES_INGEST_URI copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$predixServicesLogDir"
fi

if TIMESERIES_QUERY_URI=$(cf env $TEMP_APP | grep -m 100 uri | grep time-series | awk -F"\"" '{print $4}'); then
	__append_new_line_log "TIMESERIES_QUERY_URI copied from environmental variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$predixServicesLogDir"
fi

# Create instance of Predix Asset Service
__try_create_service $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}" "Predix Asset"

# Bind Temp App to Asset Instance
__try_bind $1 $ASSET_INSTANCE_NAME

# Get the Zone ID from the environment variables (for use when querying Asset data)
if ASSET_ZONE_ID=$(cf env $1 | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	if [[ "$ASSET_ZONE_ID" == "" ]] ; then
		__error_exit "The TimeSeries Zone ID was not found for \"$1\"..." "$predixServicesLogDir"
	fi
	__append_new_line_log "ASSET_ZONE_ID copied from environment variables!" "$predixServicesLogDir"
else
	__error_exit "There was an error getting ASSET_ZONE_ID..." "$predixServicesLogDir"
fi

# Create client ID for generic use by applications - including timeseries and asset scope
__append_new_head_log "Registering Client on UAA to access the Predix Services" "-" "$predixServicesLogDir"
__createUaaClient "$uaaURL" "$TIMESERIES_ZONE_ID" "$ASSET_SERVICE_NAME" "$ASSET_ZONE_ID"

# Create a new user account
__append_new_head_log "Creating User on UAA to login to the application" "-" "$predixServicesLogDir"
__addUaaUser "$uaaURL"

# Get the Asset URI and generate Asset body from the enviroment variables (for use when querying and posting data)
if assetURI=$(cf env $TEMP_APP | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
	__append_new_line_log "Asset URI copied from environment variables! $assetURI" "$predixServicesLogDir"
else
	__error_exit "There was an error getting Asset URI..." "$predixServicesLogDir"
fi

# Clean input for machine type and tag, no spaces allowed
ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}

assetPostBody=$(printf "[{\"uri\": \"%s\", \"tag\": \"%s\", \"description\": \"%s\"}]%s" "/$ASSET_TYPE/$ASSET_TAG_NOSPACE" "$ASSET_TAG_NOSPACE" "$ASSET_DESCRIPTION")

__append_new_line_log "Creating Asset with tags" "$predixServicesLogDir"
echo "Asset Post Body : $assetPostBody"
echo "Asset URL : $assetURI"
createAsset "$uaaURL" "$assetURI" "$ASSET_ZONE_ID" "$assetPostBody"

cd "$predixServicesSetupRootDir"

__append_new_line_log "Predix Services Configurations found in file: \"$SUMMARY_TEXTFILE\"" "$predixServicesLogDir"

echo ""  >> $SUMMARY_TEXTFILE
echo "Predix Services Configuration"  >> $SUMMARY_TEXTFILE
echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
echo ""  >> $SUMMARY_TEXTFILE
echo "Installed UAA with a client_id/secret (for your app) and a user/password (for your users to log in to your app)" >> $SUMMARY_TEXTFILE
echo "Installed Time Series and added time series scopes as client_id authorities" >> $SUMMARY_TEXTFILE
echo "Installed Asset and added asset scopes as client_id authorities" >> $SUMMARY_TEXTFILE
echo "" >> $SUMMARY_TEXTFILE
echo "UAA URL: $uaaURL" >> $SUMMARY_TEXTFILE
echo "UAA Admin Client ID: admin" >> $SUMMARY_TEXTFILE
echo "UAA Admin Client Secret: $UAA_ADMIN_SECRET" >> $SUMMARY_TEXTFILE
echo "UAA Generic Client ID: $UAA_CLIENTID_GENERIC" >> $SUMMARY_TEXTFILE
echo "UAA Generic Client Secret: $UAA_CLIENTID_GENERIC_SECRET" >> $SUMMARY_TEXTFILE
echo "UAA User ID: $UAA_USER_NAME" >> $SUMMARY_TEXTFILE
echo "UAA User PASSWORD: $UAA_USER_PASSWORD" >> $SUMMARY_TEXTFILE
echo "TimeSeries Ingest URL:  $TIMESERIES_INGEST_URI" >> $SUMMARY_TEXTFILE
echo "TimeSeries Query URL:  $TIMESERIES_QUERY_URI" >> $SUMMARY_TEXTFILE
echo "TimeSeries ZoneID: $TIMESERIES_ZONE_ID" >> $SUMMARY_TEXTFILE
echo "Asset URL:  $assetURI" >> $SUMMARY_TEXTFILE
echo "Asset Zone ID: $ASSET_ZONE_ID" >> $SUMMARY_TEXTFILE

__append_new_head_log "Created Predix Services!" "-" "$predixServicesLogDir"
