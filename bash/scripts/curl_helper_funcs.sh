#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"

trap "trap_ctrlc" 2

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015

# These are a group of helper methods that will perform CURL commands
#

#	----------------------------------------------------------------
#	Function for finding an attribute value in a JSON string
#		Accepts 2 argument:
#			string of the JSON
#     string of what property to look for
#  Returns:
#     String of the JSON attribute value
#	----------------------------------------------------------------

function __jsonval {
    __validate_num_arguments 2 $# "\"curl_helper_funcs:__jsonval\" expected in order: String of JSON, String of property to look for" "$logDir"

    temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
    echo ${temp##*|}
}

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 1 argument:
#			string of UAA URL
#  Returns:
#     String of the the UAA Admin Token
#	----------------------------------------------------------------
function __getUaaAdminToken
{
  if [[ "1" -ne "$#" ]]; then
		echo ""
  else
    UAA_ADMIN_BASE64=$(echo -ne admin:$UAA_ADMIN_SECRET | base64)
    responseCurl=`curl --silent -X GET "$1/oauth/token?grant_type=client_credentials" -H "Authorization: Basic $UAA_ADMIN_BASE64" -H "Content-Type: application/x-www-form-urlencoded"`
    tokenType=$( __jsonval "$responseCurl" "token_type" )
    accessToken=$( __jsonval "$responseCurl" "access_token" )

    echo "$tokenType $accessToken"
	fi
}

#	----------------------------------------------------------------
#	Function for getting a Client Token from UAA
#		Accepts 3 arguments:
#			string of UAA URL
#			string of Client Id
#			string of Client Id Secret
#  Returns:
#     String of the the UAA Token
#	----------------------------------------------------------------
function __getUaaClientToken
{

    UAA_ADMIN_BASE64=$(echo -ne $2:$3 | base64)
    responseCurl=`curl --silent -X GET "$1/oauth/token?grant_type=client_credentials" -H "Authorization: Basic $UAA_ADMIN_BASE64" -H "Content-Type: application/x-www-form-urlencoded"`
    tokenType=$( __jsonval "$responseCurl" "token_type" )
    accessToken=$( __jsonval "$responseCurl" "access_token" )

    echo "$tokenType $accessToken"
}

#---------------------------------
# Check if the clientId exists and return the clientId details as json
# Accepts 3 arguments
#   String UAA URI
#   String UAA ClientId
#   Var ResonseStatus
#
function __checkUaaClient
{
  __validate_num_arguments 3 $# "\"curl_helper_funcs:__checkUaaClient\" expected in order: UAA URI, UAA ClientId, Status Response" "$logDir"

  __append_new_line_log "Check UAA Client" "$logDir"

  echo "UAA_ADMIN_TOKEN=$UAA_ADMIN_TOKEN"
  if [[ "$UAA_ADMIN_TOKEN" == "" ]]; then
    __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$logDir"
    adminUaaToken=$( __getUaaAdminToken "$1" )
    UAA_ADMIN_TOKEN=$adminUaaToken
  fi


  if [ ${#UAA_ADMIN_TOKEN} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$logDir"
  else
    __append_new_line_log "Making CURL GET request to get UAA Client ID \"$2\"..." "$logDir"
    curlCmd="curl --write-out %{http_code} \"$1/oauth/clients/$2\" -H \"Pragma: no-cache\" -H \"Content-Type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: $UAA_ADMIN_TOKEN\""
    echo $curlCmd
    local responseCurl=$(curl --write-out %{http_code} --output /dev/null "$1/oauth/clients/$2" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $UAA_ADMIN_TOKEN")
    #__append_new_line_log "get uaa client id : $responseCurl"
    if [[ $responseCurl -eq 200 ]]; then
      __append_new_line_log "Client Id found" "$logDir"
    else
      if [[ $responseCurl -eq 404 ]]; then
      __append_new_line_log "Client Id Not found" "$logDir"
      else
        __error_exit "Failed to make request to get UAA Client to \"$1\"" "$logDir"
      fi
    fi
    eval $3=$responseCurl
  fi
}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 3 argument:
#			string of UAA URI
#			string of clientId to create
#			string of clientIdsecret
#
#	----------------------------------------------------------------
function __createUaaAppClient
{
  __validate_num_arguments 3 $# "\"curl_helper_funcs:__createUaaAppClient\" expected in order: UAA_URI ClientId ClientIdSecret" "$logDir"
  dataBinary="{\"client_id\":\"$2\",\"client_secret\":\"$3\",\"scope\":[\"acs.policies.read\",\"acs.policies.write\",\"acs.attributes.read\",\"uaa.none\",\"openid\"],\"authorized_grant_types\":[\"client_credentials\"],\"authorities\":[\"openid\",\"uaa.none\",\"uaa.resource\"],\"autoapprove\":[\"openid\"],\"allowedproviders\":[\"uaa\"]}"
  __createUaaClient $1 $2 $3 $dataBinary
}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 3 argument:
#			string of UAA URI
#			string of clientId to create
#			string of clientIdsecret
#
#	----------------------------------------------------------------
function __createUaaLoginClient
{
  __validate_num_arguments 3 $# "\"curl_helper_funcs:__createUaaLoginClient\" expected in order: UAA_URI ClientId ClientIdSecret" "$logDir"
  dataBinary="{\"client_id\":\"$2\",\"client_secret\":\"$3\",\"scope\":[\"uaa.none\",\"openid\"],\"authorized_grant_types\":[\"client_credentials\",\"authorization_code\",\"refresh_token\"],\"authorities\":[\"openid\",\"uaa.none\",\"uaa.resource\"],\"autoapprove\":[\"openid\"],\"allowedproviders\":[\"uaa\"],\"redirect_uri\":[\"https://*.predix.io/**\",\"http://localhost:5000/**\"]}"
  __createUaaClient $1 $2 $3 $dataBinary
}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 3 argument:
#			string of UAA URI
#			string of clientId to create
#			string of clientIdsecret
#
#	----------------------------------------------------------------
function __createDeviceClient
{
  __validate_num_arguments 3 $# "\"curl_helper_funcs:__createDeviceClient\" expected in order: UAA_URI ClientId ClientIdSecret" "$logDir"
  dataBinary="{\"client_id\":\"$2\",\"client_secret\":\"$3\",\"scope\":[\"uaa.none\",\"openid\"],\"authorized_grant_types\":[\"client_credentials\",\"authorization_code\",\"refresh_token\"],\"authorities\":[\"openid\",\"uaa.none\",\"uaa.resource\"],\"autoapprove\":[\"openid\"],\"allowedproviders\":[\"uaa\"],\"redirect_uri\":[\"https://*.predix.io/**\",\"http://localhost:5000/**\"]}"
  __createUaaClient $1 $2 $3 $dataBinary
}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 4 argument:
#			string of UAA URI
#			string of clientId to create
#			string of clientIdsecret
#			string of dataBinary request
#
#	----------------------------------------------------------------
function __createUaaClient
{
  __validate_num_arguments 4 $# "\"curl_helper_funcs:__createUaaClient\" expected in order: UAA_URI ClientId ClientIdSecret CurlToUse" "$logDir"
  __append_new_head_log "Create UAA Client $2 to secure the application" "-" "$logDir"

  __append_new_line_log "Create UAA Client: UAA Uri=$1" "$logDir"

  if [[ "$UAA_ADMIN_TOKEN" == "" ]]; then
    __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$logDir"
    adminUaaToken=$( __getUaaAdminToken "$1" )
    UAA_ADMIN_TOKEN=$adminUaaToken
  fi

  if [ ${#UAA_ADMIN_TOKEN} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$logDir"
  else
    if [[ "$UAA_URL" == "" ]]; then
      getUaaUrl $TEMP_APP
    fi

    ## check if the client exists
    __checkUaaClient $UAA_URL $2 getResponseStatus
    if [[ $getResponseStatus -eq 200 ]]; then
        __append_new_line_log "Client Found - No need to Create one" "$logDir"
    else
      # call to create a new app client id
      __append_new_line_log "Making CURL GET request to create UAA Client ID \"$2\"..." "$logDir"
      curlCmd="curl \"$1/oauth/clients\" -H \"Pragma: no-cache\" -H \"Content-Type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: $UAA_ADMIN_TOKEN\" --data-binary "$4""
      echo $curlCmd
      responseCurl=`curl "$1/oauth/clients" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $UAA_ADMIN_TOKEN" --data-binary $4`
      echo ""
      echo $responseCurl

      if [ ${#responseCurl} -lt 3 ]; then
        __error_exit "Failed to make request to create UAA User to \"$1\"" "$logDir"
      else
        # If the response has a attribute for "error" ,
        # AND not a value of "Client already exists: $UAA_CLIENTID_GENERIC" for attribute "error_description" then fail
        errorAttribute=$( __jsonval "$responseCurl" "error" )
        errorDescriptionAttribute=$( __jsonval "$responseCurl" "error_description" )

        if [ ${#errorAttribute} -gt 3 ]; then
          if [ "$errorDescriptionAttribute" != "Client already exists: $2" ]; then
            __error_exit "The request failed to successfully create or reuse the Client ID. error=$errorDescriptionAttribute response=$errorAttribute" "$logDir"
          else
            __append_new_line_log "Successfully re-using existing Client ID: \"$2\"" "$logDir"
          fi
        else
          __append_new_line_log "Successfully created new Client ID: \"$2\"" "$logDir"
        fi
      fi
    fi
  fi

}
#	----------------------------------------------------------------
#	Function for adding Timeseries Authorities
#		Accepts 1 arguments:
#     String of UAA ClientId
#	----------------------------------------------------------------
function __addTimeseriesAuthorities {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addTimeseriesAuthorities\" expected in order: Client Id " "$logDir"

  if [[ "$UAA_URL" == "" ]]; then
    getUaaUrl $TEMP_APP
  fi
  if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
    getTimeseriesZoneId $TEMP_APP
  fi
  __append_new_line_log "Add Timeseries Authorities: TimeseriesZoneId=$TIMESERIES_ZONE_ID" "$logDir"
  ## check if the client exists
  __checkUaaClient $UAA_URL $1 getResponseStatus
  if [[ $getResponseStatus -eq 200 ]]; then
      _arrayScope=("timeseries.zones.$TIMESERIES_ZONE_ID.query" "timeseries.zones.$TIMESERIES_ZONE_ID.ingest" "timeseries.zones.$TIMESERIES_ZONE_ID.user")
      __updateUaaClient "$uaaURL" "$1" _arrayScope[@] _arrayScope[@]
  fi
}

#	----------------------------------------------------------------
#	Function for adding Eventhub Authorities
#		Accepts 1 arguments:
#     String of UAA ClientId
#	----------------------------------------------------------------
function __addEventHubAuthorities {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addEventHubAuthorities\" expected in order: Client Id " "$logDir"

  if [[ "$UAA_URL" == "" ]]; then
    getUaaUrl $TEMP_APP
  fi
  if [[ "$EVENTHUB_ZONE_ID" == "" ]]; then
    getEventHubZoneId $TEMP_APP
  fi
  __append_new_line_log "Add Eventhub Authorities: EventHubZoneId=$EVENTHUB_ZONE_ID" "$logDir"
  ## check if the client exists
  __checkUaaClient $UAA_URL $1 getResponseStatus
  if [[ $getResponseStatus -eq 200 ]]; then
      _arrayScope=("eventhub.zones.$EVENTHUB_ZONE_ID.publish" "eventhub.zones.$EVENTHUB_ZONE_ID.subscribe" "eventhub.zones.$EVENTHUB_ZONE_ID.user")
      __updateUaaClient "$uaaURL" "$1" _arrayScope[@] _arrayScope[@]
  fi
}
#	----------------------------------------------------------------
#	Function for adding ACS Authorities
#		Accepts 1 arguments:
#     String of UAA ClientId
#	----------------------------------------------------------------
function __addAcsAuthorities {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addAcsAuthorities\" expected in order: Client Id " "$logDir"

  if [[ "$UAA_URL" == "" ]]; then
    getUaaUrl $TEMP_APP
  fi
  if [[ "$ACS_ZONE_ID" == "" ]]; then
    getAcsZoneId $ACCESS_CONTROL_SERVICE_INSTANCE_NAME
  fi
  __append_new_line_log "Add Acs Authorities: AcsZoneId=$ACS_ZONE_ID" "$logDir"

  ## check if the client exists
  __checkUaaClient $UAA_URL $1 getResponseStatus
  if [[ $getResponseStatus -eq 200 ]]; then
      _arrayScope=("predix-acs.zones.$ACS_ZONE_ID.user")
      __updateUaaClient "$uaaURL" "$1" _arrayScope[@] _arrayScope[@]
  fi
}
#	----------------------------------------------------------------
#	Function for adding Asset Authorities
#		Accepts 1 arguments:
#     String of UAA ClientId
#	----------------------------------------------------------------
function __addAssetAuthorities {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addAssetAuthorities\" expected in order: Client Id " "$logDir"

  __append_new_line_log "Add Asset Authorities: AssetServiceName=$ASSET_SERVICE_NAME, AssetZoneId=$ASSET_ZONE_ID" "$logDir"
  if [[ "$UAA_URL" == "" ]]; then
    getUaaUrl $TEMP_APP
  fi
  if [[ "$ASSET_ZONE_ID" == "" ]]; then
    getAssetZoneId $1
  fi

  ## check if the client exists
  __checkUaaClient $UAA_URL $1 getResponseStatus
  if [[ $getResponseStatus -eq 200 ]]; then
      _arrayScope=("$ASSET_SERVICE_NAME.zones.$ASSET_ZONE_ID.user")
      __updateUaaClient "$uaaURL" "$1" _arrayScope[@] _arrayScope[@]
  fi
}

#	----------------------------------------------------------------
#	Function for adding Asset Authorities
#		Accepts 1 arguments:
#     String of UAA ClientId
#	----------------------------------------------------------------
function __addAnalyticFrameworkAuthorities {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addAnalyticFrameworkAuthorities\" expected in order: Client Id " "$logDir"
  if [[ "$UAA_URL" == "" ]]; then
    getUaaUrl $TEMP_APP
  fi
  if [[ "$AF_ZONE_ID" == "" ]]; then
    getAFZoneId $TEMP_APP
  fi
  __append_new_line_log "Add Analytic Framwork Authorities: AnalyticFrameworkServiceName=$ANALYTIC_FRAMEWORK_SERVICE_NAME, AnalyticFrameworkZoneId=$AF_ZONE_ID" "$logDir"

  ## check if the client exists
  __checkUaaClient $UAA_URL $1 getResponseStatus
  if [[ $getResponseStatus -eq 200 ]]; then
      _arrayScope=("analytics.zones.$AF_ZONE_ID.user")
      __updateUaaClient "$uaaURL" "$1" _arrayScope[@] _arrayScope[@]
  fi
}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID - Updated
#		Accepts 4 argument:
#			string of UAA URI
#     string of CLIENT ID to update
#     array of SCOPE to be added
#     array of AUTORITIES to be added
#
#	----------------------------------------------------------------
function __updateUaaClient
{
  __validate_num_arguments 4 $# "\"curl_helper_funcs:__updateUaaClient\" expected in order: UAA URI, Client Id, Array of SCOPE to be added , Array of Authorities to be added " "$logDir"
  __append_new_head_log "Update UAA Client $2 to secure the application" "-" "$logDir"

  __append_new_line_log "Udate Uaa Client with new Scopes and Authorities" "$logDir"

  declare -a arrayScopes=("${!3}")
  declare -a arrayAuthorities=("${!4}")

  if [[ "$UAA_ADMIN_TOKEN" == "" ]]; then
    __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$logDir"
    adminUaaToken=$( __getUaaAdminToken "$1" )
    UAA_ADMIN_TOKEN=$adminUaaToken
  fi

  if [ ${#UAA_ADMIN_TOKEN} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$logDir"
  else
    __append_new_line_log "Making CURL GET request to update UAA Client ID \"$2\"..." "$logDir"

    responseCurl=`curl "$1/oauth/clients/$2" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $UAA_ADMIN_TOKEN"`

    if [ ${#responseCurl} -lt 3 ]; then
      __error_exit "Failed to make request to Get client \"$1\"" "$logDir"
    else
      # If the response has a attribute for "error" ,
      # AND not a value of "Client already exists: $UAA_CLIENTID_GENERIC" for attribute "error_description" then fail
      #declare -a additionScopes=()
      local jsonjqresponse=$(echo $responseCurl)
      local updateClientFlag="false"
      for i in "${arrayScopes[@]}"
      do
        if echo "$responseCurl" | grep -q "$i"; then
          echo "found in the scope $i"
        else
          local jsonjqresponse=$(echo $jsonjqresponse | jq ".scope |= .+ [\"$i\"]")
          updateClientFlag="true"
          echo "adding to scope $i"
        fi
      done

      #declare -a additionAuthorities=()
      for i in "${arrayAuthorities[@]}"
      do
        if echo "$responseCurl" | grep -q "$i"; then
          echo "found in the authorities $i"
        else
          local jsonjqresponse=$(echo $jsonjqresponse | jq ".authorities |= .+ [\"$i\"]")
          updateClientFlag="true"
          echo "adding to authorities $i"
        fi
      done

      if [ "$updateClientFlag" = "true" ]; then
        postbody="$jsonjqresponse"
        echo $postbody
        __append_new_line_log "Making CURL request to update UAA Client ID \"$2\"..." "$logDir"

        responseCurl=`curl --write-out %{http_code} --output /dev/null "$1/oauth/clients/$2" -X PUT -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $UAA_ADMIN_TOKEN" --data-binary "$postbody"`

        if [[ $responseCurl -eq 200 ]]; then
          __append_new_line_log "Client Id update successful" "$logDir"
        else
          if [[ $responseCurl -eq 404 ]]; then
          __append_new_line_log "Client Id update failed " "$logDir"
          else
            __error_exit "Failed to make request to update UAA Client to \"$1\"" "$logDir"
          fi
        fi
      else
        __append_new_line_log "Update Client call not needed all scope and authorities are set." "$logDir"
      fi
    fi
  fi

}

#	----------------------------------------------------------------
#	Function for adding a UAA User
#		Accepts 1 argument:
#			string of UAA URI
#	----------------------------------------------------------------
function __addUaaUser
{
  __append_new_head_log "Creating User $1 on UAA to login to the application" "-" "$logDir"

  __validate_num_arguments 1 $# "\"curl_helper_funcs:__addUaaUser\" expected in order: UAA URI" "$logDir"

  if [[ "$UAA_ADMIN_TOKEN" == "" ]]; then
    __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$logDir"
    adminUaaToken=$( __getUaaAdminToken "$1" )
    UAA_ADMIN_TOKEN=$adminUaaToken
  fi

  if [ ${#UAA_ADMIN_TOKEN} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$logDir"
  else
    __append_new_line_log "Making CURL GET request to create UAA user \"$UAA_USER_NAME\"..." "$logDir"

    curlCmd="curl \"$1/Users\" -H \"Pragma: no-cache\" -H \"Content-Type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: $UAA_ADMIN_TOKEN\" --data-binary '{\"userName\":\"'$UAA_USER_NAME'\",\"password\":\"'$UAA_USER_PASSWORD'\",\"emails\":[{\"value\":\"'$UAA_USER_EMAIL'\"}]}'"
    echo $curlCmd
    responseCurl=`curl "$1/Users" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $UAA_ADMIN_TOKEN" --data-binary '{"userName":"'$UAA_USER_NAME'","password":"'$UAA_USER_PASSWORD'","emails":[{"value":"'$UAA_USER_EMAIL'"}]}'`

    if [ ${#responseCurl} -lt 3 ]; then
      __error_exit "Failed to make request to create UAA User to \"$1\"" "$logDir"
    else
      # If the response has a attribute for "error" ,
      # AND not a value of "Username already in use: $UAA_USER_NAME" for attribute "error_description" then fail
      errorAttribute=$( __jsonval "$responseCurl" "error" )
      errorDescriptionAttribute=$( __jsonval "$responseCurl" "error_description" )

      if [ ${#errorAttribute} -gt 3 ]; then
        if [ "$errorDescriptionAttribute" != "Username already in use: $UAA_USER_NAME" ]; then
          __error_exit "The request failed to successfully create or reuse the UAA User \"$UAA_USER_NAME\"" "$logDir"
        else
          __append_new_line_log "Successfully re-using existing UAA User: \"$UAA_USER_NAME\"" "$logDir"
        fi
      else
        __append_new_line_log "Successfully created new UAA User: \"$UAA_USER_NAME\"" "$logDir"
      fi
    fi
  fi
}

#	----------------------------------------------------------------
#	Function for creating an asset
#		Accepts 6 arguments:
#			string of UAA URL
#			string of Client Id
#			string of Client Id Secret
#     string of assetURI
#     string of assetZoneId
#     string of assetPostBody
#  Returns:
#	----------------------------------------------------------------
function createAsset
{
  __validate_num_arguments 6 $# "\"curl_helper_funcs:createAsset\" expected in order: UAA URI, Client Id, ClientIdSecret, Asset URI, AssetZoneId, AssetPostBody " "$logDir"

  #$TRUSTED_ISSUER_ID $assetURI $ASSET_ZONE_ID $assetPostBody
  clientToken=$( __getUaaClientToken $1 $2 $3)
  __append_new_line_log "Got UAA Client Token for $2" "$logDir"
  createAssetCMD="curl --silent -X POST $4/asset -H 'Predix-Zone-Id: $5' -H 'Content-Type: application/json' -H 'Authorization: $clientToken' --data '$6'"
  echo $createAssetCMD
  curl --silent -X POST $4/asset -H "Predix-Zone-Id: $5" -H "Content-Type: application/json" -H "Authorization: $clientToken" --data "$6"

}

#	----------------------------------------------------------------
#	Function for creating an asset with metadata
#		Accepts 6 arguments:
#			string of UAA URL
#			string of Client Id
#			string of Client Id Secret
#     string of assetURI  - for later use of passing to data-exchange
#     string of assetZoneId - for later use of passing to data-exchange
#     string of dataexhangeURI
#     string of metaData JSON file
#     string of assetModel JSON file
#  Returns:
#	----------------------------------------------------------------
function createAssetWithMetaData
{
  __validate_num_arguments 8 $# "\"curl_helper_funcs:createAssetWithMetaData\" expected in order: UAA URI, Client Id, ClientIdSecret, Asset URI, AssetZoneId, AssetPostBody, DataExchangeURI, MetaDataJsonFile, AssetModelJsonFile  " "$logDir"

  clientToken=$( __getUaaClientToken $1 $2 $3)
  __append_new_line_log "Got UAA Client Token for $2" "$logDir"
  metadataFile=`echo $7`
  assetJsonFile=`echo $8`
  metadataRequest=$( cat $metadataFile )
  cp $assetJsonFile asset_upload_file.json
  echo $metadataRequest
  createAssetCMD='curl -X POST "https://'$6'/services/fdhrouter/fielddatahandler/putfielddatafile" -H "Authorization: '$clientToken'"  -H "Content-Type: multipart/form-data;" -H "Accept: application/json" -F "file=@'"asset_upload_file.json"'" -F '"'"'"putfielddata"='$metadataRequest"'"
  echo $createAssetCMD
  responseCurl=`curl --write-out %{http_code} --output /dev/null -X POST "https://$6/services/fdhrouter/fielddatahandler/putfielddatafile" -H "Authorization: $clientToken"  -H "Content-Type: multipart/form-data;" -H "Accept: application/json" -F "file=@asset_upload_file.json" -F "putfielddata=$metadataRequest"`
  echo ""
  echo $responseCurl
  if [[ $responseCurl == 200* ]]; then
    __append_new_line_log "Asset Model Created" "$logDir"
  else
    if [[ $responseCurl == 404* ]]; then
      __error_exit "Unable to Create Asset Model - Service $6 Not found" "$logDir"
    else
      __error_exit "Failed to make request to Create Asset Model to \"$1\"" "$logDir"
    fi
  fi
}

function fetchVCAPSInfo
{
  __validate_num_arguments 1 $# "\"curl_helper_funcs:fetchVCAPSInfo\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"

  echo "WARNING: fetchVCAPSInfo function has been deprecated and no longer works.  Script should call a specific function in curl_helper_funcs.sh"
  # Get the UAA enviorment variables (VCAPS)
  # if [[ "$trustedIssuerID" == "" ]]; then
  #   getTrustedIssuerId $1
  # fi
  #
  # if [[ "$UAA_URL" == "" ]]; then
  #   getUaaUrl $1
  # fi
  #
	# if TIMESERIES_INGEST_URI=$(px env $TEMP_APP | grep -m 100 uri | grep wss: | awk -F"\"" '{print $4}'); then
	# 	if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
	# 		__error_exit "The TIMESERIES_INGEST_URI was not found for \"$TEMP_APP\"..." "$logDir"
	# 	fi
  #   __append_new_line_log " TIMESERIES_INGEST_URI copied from VCAP environmental variables!" "$logDir"
  #   export TIMESERIES_INGEST_URI="${TIMESERIES_INGEST_URI}"
	# else
	# 	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$logDir"
	# fi
  #
  # if TIMESERIES_QUERY_URI=$(px env $TEMP_APP | grep -m 100 uri | grep datapoints | awk -F"\"" '{print $4}'); then
	# 	if [[ "$TIMESERIES_QUERY_URI" == "" ]] ; then
	# 		__error_exit "The TIMESERIES_QUERY_URI was not found for \"$TEMP_APP\"..." "$logDir"
	# 	fi
  #   __append_new_line_log " TIMESERIES_QUERY_URI copied from VCAP environmental variables!" "$logDir"
  #   export TIMESERIES_QUERY_URI="${TIMESERIES_QUERY_URI}"
	# else
	# 	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$logDir"
	# fi
  #
  #
  # if assetURI=$(px env $TEMP_APP  | grep uri*| grep predix-asset* | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
	# 	if [[ "$assetURI" == "" ]] ; then
	# 		__error_exit "The Asset URI was not found for \"$TEMP_APP\"..." "$logDir"
	# 	fi
	# 	__append_new_line_log "Asset Service URI : ${assetURI}" "$logDir"
  #   export ASSET_URL="${assetURI}"
  #   export ASSET_URI="${assetURI}"
	# else
	# 	__error_exit "There was an error getting assetURI..." "$logDir"
	# fi
  #

}

function getUaaUrl() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getUaaUrl\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"

  if uaaURL=$(px env $1 | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
    if [[ "$uaaURL" == "" ]] ; then
      __error_exit "The UAA URL was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "UAA URL=$uaaURL copied from VCAP environmental variables!" "$logDir"
    export UAA_URL="${uaaURL}"
  else
    __error_exit "There was an error getting the UAA URL..." "$logDir"
  fi
}

function getTimeseriesIngestUri() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getTimeseriesIngestUri\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if TIMESERIES_INGEST_URI=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-timeseries"][].credentials.ingest.uri' | tr -d '"'| head -1); then
  	if [[ "$TIMESERIES_INGEST_URI" == "" ]] ; then
  		__error_exit "The TIMESERIES_INGEST_URI was not found for \"$1\"..." "$logDir"
  	fi
    __append_new_line_log " TIMESERIES_INGEST_URI=$TIMESERIES_INGEST_URI copied from VCAP environmental variables!" "$logDir"
    export TIMESERIES_INGEST_URI="${TIMESERIES_INGEST_URI}"
  else
  	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$logDir"
  fi
}

function getTimeseriesQueryUri() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getTimeseriesQueryUri\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if TIMESERIES_QUERY_URI=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-timeseries"][].credentials.query.uri' | tr -d '"'| head -1); then
    __append_new_line_log "Timeseries Query URI copied from environment variables! $TIMESERIES_QUERY_URI" "$logDir"
  else
    __error_exit "There was an error getting Timeseries Query URI..." "$logDir"
  fi
}

function getTimeseriesZoneId() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getTimeseriesZoneId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if TIMESERIES_ZONE_ID=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-timeseries"][].credentials.query["zone-http-header-value"]' | tr -d '"'| head -1); then
    if [[ "$TIMESERIES_ZONE_ID" == "" ]] ; then
      __error_exit "The TIMESERIES_ZONE_ID was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "TIMESERIES_ZONE_ID=$TIMESERIES_ZONE_ID copied from VCAP environmental variables!" "$logDir"
    export TIMESERIES_ZONE_ID="${TIMESERIES_ZONE_ID}"
	else
		__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$logDir"
	fi
}
function getEventHubIngestUri() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getEventHubIngestUri\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  echo "$VCAP_JSON"
  if EVENTHUB_INGEST_URI=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-event-hub"][].credentials.ingest.uri' | tr -d '"'| head -1); then
    if [[ "$EVENTHUB_INGEST_URI" == "" ]] ; then
      __error_exit "The EVENTHUB_INGEST_URI was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "EVENTHUB_INGEST_URI=$EVENTHUB_INGEST_URI copied from VCAP environmental variables!" "$logDir"
    export EVENTHUB_INGEST_URI="${EVENTHUB_INGEST_URI}"
	else
		__error_exit "There was an error getting EVENTHUB_ZONE_ID..." "$logDir"
	fi
}
function getEventHubZoneId() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getEventHubZoneId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if EVENTHUB_ZONE_ID=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-event-hub"][].credentials.query["zone-http-header-value"]'); then
    if [[ "$EVENTHUB_ZONE_ID" == "" ]] ; then
      __error_exit "The EVENTHUB_ZONE_ID was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "EVENTHUB_ZONE_ID=$EVENTHUB_ZONE_ID copied from VCAP environmental variables!" "$logDir"
    export EVENTHUB_ZONE_ID="${EVENTHUB_ZONE_ID}"
	else
		__error_exit "There was an error getting EVENTHUB_ZONE_ID..." "$logDir"
	fi
}
function getAssetUri() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getAssetUri\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  if ASSET_URI=$(px env $1 | grep -m 100 uri | grep asset | awk -F"\"" '{print $4}'); then
		__append_new_line_log "Asset URI copied from environment variables! $ASSET_URI" "$logDir"
	else
		__error_exit "There was an error getting Asset URI..." "$logDir"
	fi
}
function getAssetZoneId() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getAssetZoneId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  #note double quotes needed because of dash
  #note square brackets needed for jq 1.3 compatibility and jenkins still has that sometimes
  if ASSET_ZONE_ID=$(echo $VCAP_JSON | jq -r '.["VCAP_SERVICES"]["predix-asset"][].credentials.zone["http-header-value"]'); then
  	if [[ "$ASSET_ZONE_ID" == "" ]] ; then
	    __error_exit "The Asset Zone ID was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "ASSET_ZONE_ID=$ASSET_ZONE_ID copied from VCAP environment variables!" "$logDir"
    export ASSET_ZONE_ID="${ASSET_ZONE_ID}"
  else
    __error_exit "There was an error getting ASSET_ZONE_ID using command echo $VCAP_JSON | jq -r '.[\"VCAP_SERVICES\"][\"predix-asset\"][].credentials.zone[\"http-header-value\"]'" "$logDir"
  fi
}

function getAFUri() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getAFUri\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if AF_URI=$(echo $VCAP_JSON |  jq -r '.["VCAP_SERVICES"]["predix-analytics-framework"][].credentials["execution_uri"]'); then
		__append_new_line_log "AF URI copied from environment variables! $AF_URI" "$logDir"
	else
		__error_exit "There was an error getting AF URI..." "$logDir"
	fi
}

function getVCAPJSON() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getsVCAPJSON\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  if VCAP=$(px env $1 | sed '/VCAP_APPLICATION/q' | sed '$ d' | sed '$ d' ); then
    while true; do
      if [[ $VCAP == {* ]]; then
        echo "$VCAP"
        break;
      fi
      if ! VCAP=$(echo "$VCAP" | tail -n +2); then #lop off one line
        __error_exit "There was an error getting VCAP JSON..." "$logDir"
      fi
    done
	else
		__error_exit "There was an error getting VCAP JSON..." "$logDir"
	fi
}

function getAFZoneId() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getAFZoneId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"
  VCAP_JSON=$(getVCAPJSON $1)
  if AF_ZONE_ID=$(echo $VCAP_JSON |  jq -r '.["VCAP_SERVICES"]["predix-analytics-framework"][].credentials["zone-http-header-value"]'); then
	  if [[ "$AF_ZONE_ID" == "" ]] ; then
	    __error_exit "The AF Zone ID was not found for \"$1\"..." "$logDir"
	  fi
    __append_new_line_log "AF_ZONE_ID=$AF_ZONE_ID copied from VCAP environment variables!" "$logDir"
		export AF_ZONE_ID="${AF_ZONE_ID}"
	else
	  __error_exit "There was an error getting AF_ZONE_ID..." "$logDir"
	fi
}

function getTrustedIssuerId()
{
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getTrustedIssuerId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"

  if trustedIssuerID=$(px env $1 | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
		if [[ "$trustedIssuerID" == "" ]] ; then
			__error_exit "The UAA trustedIssuerID was not found for \"$1\"..." "$logDir"
		fi
		#__append_new_line_log "trustedIssuerID copied from environmental variables!" "$logDir"
    export TRUSTED_ISSUER_ID="${trustedIssuerID}"
	else
		__error_exit "There was an error getting the UAA trustedIssuerID..." "$logDir"
	fi
}

function getAcsZoneId() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getAcsZoneId\" expected in order: Name of Predix Application used to get VCAP configurations  " "$logDir"

  # Get the Zone ID from the environment variables (for use when querying Asset data)
  if acsZoneId=$(predix si $1 | tail -n +2  | jq -r 'predix-acs.zone["http-header-value"]'); then
    if [[ "$acsZoneId" == "" ]]; then
      __error_exit "The Access Control Service Zone ID was not found for \"$1\"..." "$logDir"
    fi
    __append_new_line_log "acsZoneId copied from environment variables!" "$logDir"
    export ACS_ZONE_ID=$acsZoneId
  else
    __error_exit "There was an error getting ACS_ZONE_ID..." "$logDir"
  fi
}

# Takes 3 arguments
#  app-name to query for
#  VARIABLE_NAME to store result
#  desired protocol.  (for example: https or wss)
function getUrlForAppName() {
  __validate_num_arguments 3 $# "\"curl_helper_funcs:getUrlForAppName\" expected in order: Name of Predix Application, variable name to store the URL, protocol  " "$logDir"

  local _result=$2
  local _host=$(px app $1 | grep "urls:" | awk -F" " '{print $2}');
  if [[ -z "$_host" ]]; then
    _host=$(px app $1 | grep "routes:" | awk -F" " '{print $2}')
  fi

  local _url
  if [ -z "$_host" ]; then
    __error_exit "There was an error getting App URI for: $1" "$logDir"
  else
    if [[ $3 == "" ]]; then
      _url=$_host
    else
      _url=$3://$_host
    fi

    eval $_result="'$_url'"
    __append_new_line_log "App URI copied from environment variables: $_url" "$logDir"
  fi
}

# Takes one argument: variable name in which to store result.
function getRedisServiceName() {
  __validate_num_arguments 1 $# "\"curl_helper_funcs:getRedisServiceName\" expected in order: variable name to store the result  " "$logDir"
  echo "px m | grep $REDIS_SERVICE_NAME_REG | awk -F" " '{print $1}' | head -n 1"
  local redisName=$(px m | grep $REDIS_SERVICE_NAME_REG | awk -F" " '{print $1}' | head -n 1)
  echo $redisName
  #local redisName=$(px m | grep redis | awk -F" " '{print $1}')
  local result=$1
  if [ -x "$redisName" ]; then
    __error_exit "Error find the redis service. If redis is not available in your org/space, please file a support ticket."
  else
    eval $result="'$redisName'"
    __append_new_line_log "Redis service name found: $redisName" "$logDir"
  fi

}
