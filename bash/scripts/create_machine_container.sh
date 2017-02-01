#!/bin/bash
set -e
createMachineContainterRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
createMachineContainterLogDir="$createMachineContainterRootDir/../log"

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "$createMachineContainterRootDir/variables.sh"
source "$createMachineContainterRootDir/error_handling_funcs.sh"
source "$createMachineContainterRootDir/files_helper_funcs.sh"
source "$createMachineContainterRootDir/curl_helper_funcs.sh"
trap "trap_ctrlc" 2

PROGNAME=$(basename $0)
ROOT_DIR=$(pwd)

rm -rf $MACHINE_SDK*
echo "Generating Machine container from $MACHINE_SDK"
mvn org.apache.maven.plugins:maven-dependency-plugin:2.6:copy -Dartifact=$MACHINE_GROUP_ID:$ARTIFACT_ID:$MACHINE_VERSION:$ARTIFACT_TYPE -s $MAVEN_SETTNGS_FILE -DoutputDirectory=.
if [[ -f $MACHINE_SDK_ZIP ]]; then
  BIT=$(uname -m)
  echo $(uname -a)"
  echo $(uname)"
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Downloading Eclipse : $ECLIPSE_MAC_64BIT"
    ECLIPSE_TAR_FILENAME="$(echo $ECLIPSE_MAC_64BIT |awk -F"/" '{print $NF}')"
    ECLIPSE_TAR_URL="$ECLIPSE_MAC_64BIT"
  fi
  if [ "$(uname)" == "Linux" ]; then
    if [[ "$BIT" == "x86_64" ]]; then
      ECLIPSE_TAR_FILENAME="$(echo $ECLIPSE_LINUX_64BIT |awk -F"/" '{print $NF}')"
      ECLIPSE_TAR_URL="$ECLIPSE_LINUX_64BIT"
    else
      ECLIPSE_TAR_FILENAME="$(echo $ECLIPSE_LINUX_32BIT |awk -F"/" '{print $NF}')"
      ECLIPSE_TAR_URL="$ECLIPSE_LINUX_32BIT"
    fi
  fi
  if [ "$(uname)" == "Windows" ]; then
    ECLIPSE_TAR_FILENAME="$(echo $ECLIPSE_WINDOWS_64BIT |awk -F"/" '{print $NF}')"
    ECLIPSE_TAR_URL="$ECLIPSE_WINDOWS_64BIT"
  fi
  pwd
  echo "$ECLIPSE_TAR_FILENAME"
  if [[ ! -f $ECLIPSE_TAR_FILENAME ]]; then
    curl -O $ECLIPSE_TAR_URL
  fi
  unzip -q $MACHINE_SDK_ZIP
  cd $MACHINE_SDK/utilities/containers
  echo "Generating Machine Container of type : $MACHINE_CONTAINER_TYPE"
  echo "ECLIPSE_TAR_FILENAME : $ECLIPSE_TAR_FILENAME"
  if [[ -f "GenerateContainers.sh" ]]; then
    echo "./GenerateContainers.sh -e ../../../$ECLIPSE_TAR_FILENAME -c $(echo $MACHINE_CONTAINER_TYPE | tr 'a-z' 'A-Z')"
    ./GenerateContainers.sh -e ../../../$ECLIPSE_TAR_FILENAME -c "$(echo $MACHINE_CONTAINER_TYPE | tr 'a-z' 'A-Z')"
  elif [[ -f "GenerateContainers" ]]; then
    echo "./GenerateContainers ../../../$ECLIPSE_TAR_FILENAME -$(echo $MACHINE_CONTAINER_TYPE | tr 'a-z' 'A-Z')"
    ./GenerateContainers ../../../$ECLIPSE_TAR_FILENAME "-$(echo $MACHINE_CONTAINER_TYPE | tr 'a-z' 'A-Z')"
  fi
  cd "$ROOT_DIR"
  MACHINE_HOME="$MACHINE_SDK/utilities/containers/PredixMachine-$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION"
  #fetchVCAPSInfo
  #echo "TRUSTED_ISSUER_ID     : $TRUSTED_ISSUER_ID"
  #echo "UAA URL               : $UAA_URL"
  #echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
  #echo "TIMESERIES_ZONE_ID    : $TIMESERIES_ZONE_ID"
  #echo "ASSET_URL             : $ASSET_URL"
  #echo "ASSET_ZONE_ID         : $ASSET_ZONE_ID"
  #"$createMachineContainterRootDir/machineconfig.sh" "$TRUSTED_ISSUER_ID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$UAA_URL" "$MACHINE_HOME"
  cd $MACHINE_SDK/utilities/containers/PredixMachine-$(echo $MACHINE_CONTAINER_TYPE | tr 'A-Z' 'a-z')-$MACHINE_VERSION
  rm -rf ../../../../PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip
  zip -r ../../../../PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip .
  __append_new_line_log "PredixMachine tar ball available at location `pwd`/PredixMachine$MACHINE_CONTAINER_TYPE-$MACHINE_VERSION.zip" "$createMachineContainterLogDir"
  echo "Created Machine container successfully"
else
  __error_exit "The $MACHINE_SDK_ZIP not found. Check the maven settings file or the Machine Version you provided" "$createMachineContainterLogDir"
fi
