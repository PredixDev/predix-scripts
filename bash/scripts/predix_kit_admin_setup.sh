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


	if ! [ -d "$logDir" ]; then
		mkdir "$logDir"
		chmod 744 "$logDir"
	fi

	touch "$logDir/quickstart.log"

	# Trap ctrlc and exit if encountered
	trap "trap_ctrlc" 2
	__append_new_head_log "Setting up Predix Kit Admin " "#" "$logDir"

    __predix_kit_admin_client_setup $UAA_CLIENTID_GENERIC $KIT_ADMIN_GROUP
	__predix_kit_admin_user_create $KIT_ADMIN_USER_NAME $KIT_ADMIN_USER_EMAIL $KIT_ADMIN_PASSWORD
	__predix_kit_admin_group_membership_setup $KIT_ADMIN_GROUP $KIT_ADMIN_USER_NAME

	__append_new_line_log "Predix Kit Admin Configurations found in file: \"$SUMMARY_TEXTFILE\"" "$logDir"

	echo ""  >> $SUMMARY_TEXTFILE
	echo "Predix Kit Admin  Configuration"  >> $SUMMARY_TEXTFILE
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
	echo "Predix Kit UAA User ID: $KIT_ADMIN_USER_NAME" >> $SUMMARY_TEXTFILE
	echo "Predix Kit UAA User PASSWORD: $KIT_ADMIN_PASSWORD" >> $SUMMARY_TEXTFILE
	echo "Predix Kit Group: $KIT_ADMIN_GROUP" >> $SUMMARY_TEXTFILE



	
