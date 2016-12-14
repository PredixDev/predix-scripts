#!/bin/bash
set -e
# Cleanup Script
# Authors: GE SDLP 2015
#

cleanUpPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cleanUpLogDirectory="$cleanUpPath/../log"

source "$cleanUpPath/predix_funcs.sh"
source "$cleanUpPath/variables.sh"
source "$cleanUpPath/files_helper_funcs.sh"
source "$cleanUpPath/error_handling_funcs.sh"

if ! [ -d "$cleanUpLogDirectory" ]; then
	mkdir "$cleanUpLogDirectory"
	chmod 744 "$cleanUpLogDirectory"
fi

touch "$cleanUpLogDirectory/quickstartlog.log"

# Unbind any possible services
# *****************************
__append_new_head_log "Cleaning up Apps and Services" "#" "$cleanUpLogDirectory"

__try_unbind $TEMP_APP $TIMESERIES_INSTANCE_NAME
__try_unbind $FRONT_END_APP_NAME $TIMESERIES_INSTANCE_NAME

__try_unbind $TEMP_APP $ASSET_INSTANCE_NAME
__try_unbind $FRONT_END_APP_NAME $ASSET_INSTANCE_NAME

__try_unbind $TEMP_APP $UAA_INSTANCE_NAME
__try_unbind $FRONT_END_APP_NAME $UAA_INSTANCE_NAME

# Delete the applications
# *****************************
__try_delete_app $FRONT_END_APP_NAME
__try_delete_app $TEMP_APP

# Delete the services
# *****************************
__try_delete_service $UAA_INSTANCE_NAME
__try_delete_service $TIMESERIES_INSTANCE_NAME
__try_delete_service $ASSET_INSTANCE_NAME
