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
mvn dependency:copy -Dartifact=$MACHINE_GROUP_ID:$ARTIFACT_ID:$MACHINE_VERSION:$ARTIFACT_TYPE -DoutputDirectory=.
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
    ECLIPSE_TAR_FILENAME="echo $ECLIPSE_LINUX_64BIT |awk -F"/" '{print $NF}'"
    ECLIPSE_TAR_URL="$ECLIPSE_LINUX_64BIT"
  else
    ECLIPSE_TAR_FILENAME="echo $ECLIPSE_LINUX_32BIT |awk -F"/" '{print $NF}'"
    ECLIPSE_TAR_URL="$ECLIPSE_LINUX_32BIT"
  fi
fi
if [ "$(uname)" == "Windows" ]; then
  ECLIPSE_TAR_FILENAME="echo $ECLIPSE_WINDOWS_64BIT |awk -F"/" '{print $NF}'"
  ECLIPSE_TAR_URL="$ECLIPSE_WINDOWS_64BIT"
fi
echo "$ECLIPSE_TAR_FILENAME"
if [ ! -f $ECLIPSE_TAR_FILENAME ]; then
  curl -O $ECLIPSE_MAC_64BIT
fi
unzip -q $MACHINE_SDK_ZIP
cd $MACHINE_SDK/utilities/containers
echo "ECLIPSE_TAR_FILENAME : $ECLIPSE_TAR_FILENAME"
if [[ "$(uname)" == "Darwin" ]] || [[ "$(uname)" == "Linux" ]]; then
  ./GenerateContainers.sh -e ../../../$ECLIPSE_TAR_FILENAME -c DEBUG >> $createMachineContainterLogDir/quickstartlog.log
else
  ./GenerateContainers.bat -e ../../../$ECLIPSE_TAR_FILENAME -c DEBUG
fi
cd "$ROOT_DIR"
MACHINE_HOME="$MACHINE_SDK/utilities/containers/PredixMachine-debug-$MACHINE_VERSION"
fetchVCAPSInfo
echo "TRUSTED_ISSUER_ID     : $TRUSTED_ISSUER_ID"
echo "UAA URL               : $UAA_URL"
echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
echo "TIMESERIES_ZONE_ID    : $TIMESERIES_ZONE_ID"
echo "ASSET_URL             : $ASSET_URL"
echo "ASSET_ZONE_ID         : $ASSET_ZONE_ID"
"$createMachineContainterRootDir/machineconfig.sh" "$TRUSTED_ISSUER_ID" "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$UAA_URL" "$MACHINE_HOME"
mv $MACHINE_SDK/utilities/containers/PredixMachine-debug-$MACHINE_VERSION $MACHINE_SDK/utilities/containers/PredixMachine
rm -rf PredixMachine.tar
tar -C $MACHINE_SDK/utilities/containers -cf PredixMachine.tar PredixMachine
echo "Complete"
