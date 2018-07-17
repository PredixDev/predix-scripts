#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to clone the repo,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"

trap "trap_ctrlc" 2

GIT_DIR="$rootDir/data-exchange-simulator"

if ! [ -d "$logDir" ]; then
  mkdir "$logDir"
  chmod 744 "$logDir"
fi
touch "$logDir/quickstart.log"

# ********************************** MAIN **********************************
function build-basic-app-data-simulator-main() {
  __validate_num_arguments 1 $# "\"build-basic-app-data-simulator.sh\" expected in order: String of Predix Application used to get VCAP configurations" "$logDir"

  __append_new_head_log "Build & Deploy Data-Simulator Back-end Microservice" "-" "$logDir"

  cd "$rootDir"
  if [[ "$USE_DATA_SIMULATOR" == "1" ]]; then
    # Checkout the repo
    getGitRepo "data-exchange-simulator"
    cd data-exchange-simulator

    # get values for manifest
    if [[ "$TRUSTED_ISSUER_ID" == "" ]]; then
      getTrustedIssuerIdFromInstance $UAA_INSTANCE_NAME
    fi
    if [[ "$TIMESERIES_ZONE_ID" == "" ]]; then
      getTimeseriesZoneIdFromInstance $TIMESERIES_INSTANCE_NAME
    fi
    # Edit the manifest.yml files
    #    Modify the name of the applications
    __find_and_replace "- name: .*" "- name: $DATA_SIMULATOR_APP_NAME" "manifest.yml" "$logDir"
    #    Set the clientid and base64ClientCredentials
    UAA_HOSTNAME=$(echo $uaaURL | awk -F"/" '{print $3}')
    __find_and_replace "{trustedIssuer}" "$TRUSTED_ISSUER_ID" "manifest.yml" "$logDir"
    __find_and_replace "predix_oauth_clientId: .*" "predix_oauth_clientId: $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET" "manifest.yml" "$logDir"
    CLOUD_ENDPONT=$(echo $ENDPOINT | cut -d '.' -f3-6 )

    if [[ "$USE_DATAEXCHANGE" == "1" ]]; then
      __find_and_replace "{predix.timeseries.websocket.uri}" "wss://$DATAEXCHANGE_APP_NAME"".run.$CLOUD_ENDPONT/livestream/messages" "manifest.yml" "$logDir"
    else
      TIMESERIES_INGEST_URI=wss://gateway-predix-data-services.run.$CLOUD_ENDPONT/v1/stream/messages
      __find_and_replace "{predix.timeseries.websocket.uri}" "$TIMESERIES_INGEST_URI" "manifest.yml" "$logDir"
    fi
    __find_and_replace "{predix.timeseries.zoneid}" "$TIMESERIES_ZONE_ID" "manifest.yml" "$logDir"
    cat manifest.yml

    # Push the application
    if [[ $USE_TRAINING_UAA -eq 1 ]]; then
      sed -i -e 's/uaa_service_label : predix-uaa/uaa_service_label : predix-uaa-training/' manifest.yml
    fi
    # __append_new_head_log "Retrieving the application $DATA_SIMULATOR_APP_NAME" "-" "$logDir"
    # if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
    #   mvn clean package -U -B -s $MAVEN_SETTINGS_FILE
    # else
    #   mvn clean dependency:copy -B -s $MAVEN_SETTINGS_FILE
    # fi
    mkdir -p target
    cp dist/*.jar target

    __append_new_head_log "Deploying the application $DATA_SIMULATOR_APP_NAME" "-" "$logDir"
    if px push; then
      __append_new_line_log "Successfully deployed!" "$logDir"
    else
      __append_new_line_log "Failed to deploy application. Retrying..." "$logDir"
      if px push; then
        __append_new_line_log "Successfully deployed!" "$logDir"
      else
        __error_exit "There was an error pushing using: \"px push\"" "$logDir"
      fi
    fi

    getUrlForAppName $DATA_SIMULATOR_APP_NAME APP_URL "https"

    cd ..
  fi

  if [[ ! -z $SIMULATION_FILE ]]; then
    sleep 10
    startSimulation "$APP_URL/start-simulation" "$quickstartRootDir/$SIMULATION_FILE"
  else
    __error_exit "No simulation file specified." "$logDir"
  fi

  SUMMARY_TEXTFILE="$logDir/quickstart-summary.txt"
  echo ""  >> $SUMMARY_TEXTFILE
  echo "Back-end Data Simulator Spring Boot Microservice App"  >> $SUMMARY_TEXTFILE
  echo "--------------------------------------------------"  >> $SUMMARY_TEXTFILE
  echo ""
  echo "Installed DataSimulator back-end microservice to the cloud and updated the manifest file with UAA, TimeSeries and DataExchange info"  >> $SUMMARY_TEXTFILE
  echo "App URL: https://$DATA_SIMULATOR_APP_NAME.run.$CLOUD_ENDPONT" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px env "$DATA_SIMULATOR_APP_NAME"' to view info about your back-end microservice, and the bound UAA and TimeSeries" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'px logs "$DATA_SIMULATOR_APP_NAME"' to see it sending data to Time Series" >> $SUMMARY_TEXTFILE
  echo -e "You can visit https://predix-toolkit.run.aws-usw02-pr.ice.predix.io/#!/apiLoginClient to login to UAA and do Time Series Queries.  Learn more about the Time Series API here https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1556&tag=Time%20Series&journey=Time%20Series" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'cat $quickstartRootDir/$SIMULATION_FILE' to see the name of the simulation and the start-simulation request.  You can back up the original file and make changes too, read on!" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'curl $APP_URL/stop-simulation -X POST  -H \"Content-Type: text/plain\"  --data-binary \"Sample-Random-Simulation-1\"' to stop the simulation" >> $SUMMARY_TEXTFILE
  echo -e "You can execute 'curl $APP_URL/start-simulation -X POST -H \"Content-Type: application/json\" --data-binary \"@$quickstartRootDir/$SIMULATION_FILE\"' to stop the simulation" >> $SUMMARY_TEXTFILE
  echo -e "If you prefer a UI, you can execute the stop-simulation and start-simulation commands using the Predix Toolkit at https://predix-toolkit.run.aws-usw02-pr.ice.predix.io/#!/restClient" >> $SUMMARY_TEXTFILE
  echo -e "For APM, you can follow the tutorial (https://predix.io/resources/tutorials/tutorial-details.html?tutorial_id=2585&tag=2583&journey=APM%20Basic%20Configuration&resources=2584,2579,2585) to see the data in a Dashboard" >> $SUMMARY_TEXTFILE
  
  echo ""  >> $SUMMARY_TEXTFILE

}
