#!/bin/bash
set -e
buildMavenBundleRootDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
buildMavenBundleLogDir="$buildMavenBundleRootDir/../log"

source "$buildMavenBundleRootDir/predix_funcs.sh"
source "$buildMavenBundleRootDir/variables.sh"
source "$buildMavenBundleRootDir/error_handling_funcs.sh"
source "$buildMavenBundleRootDir/files_helper_funcs.sh"
source "$buildMavenBundleRootDir/curl_helper_funcs.sh"
MACHINE_HOME="$1"
CURRENT_DIR=$(pwd)
echo "CURRENT_DIR : $CURRENT_DIR"
cd ../..
if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
  mvn -q clean install -U -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8 -f pom.xml -s $MAVEN_SETTNGS_FILE
else
  mvn clean dependency:copy -Dmdep.useBaseVersion=true -s $MAVEN_SETTNGS_FILE
fi

mvn help:active-profiles

PROJECT_ARTIFACT_ID=$(mvn org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.artifactId | grep -e '^[^\[]')
PROJECT_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.version | grep -e '^[^\[]')
MACHINE_BUNDLE="$PROJECT_ARTIFACT_ID-$PROJECT_VERSION.jar"

#SOLUTION_INI="sed \"s#MACHINE_BUNDLE_JAR#$MACHINE_BUNDLE#\" config/solution.ini > \"$MACHINE_HOME/machine/bin/vms/solution.ini\""
#echo "SOLUTION_INI : $SOLUTION_INI"
#sed "s\#MACHINE_BUNDLE_JAR\#${MACHINE_BUNDLE}\#" config/solution.ini > "$MACHINE_HOME/machine/bin/vms/solution.ini"
echo "sed \"s/{MACHINE_BUNDLE_JAR}/$MACHINE_BUNDLE/g\" config/solution.ini > \"$MACHINE_HOME/machine/bin/vms/solution.ini\""
sed "s/{MACHINE_BUNDLE_JAR}/$MACHINE_BUNDLE/g" config/solution.ini > $MACHINE_HOME/machine/bin/vms/solution.ini
#sed -i -e "s#<name>{MACHINE_BUNDLE_JAR}</name>#<name>$MACHINE_BUNDLE</name>#" config/solution.ini
#cp config/solution.ini $MACHINE_HOME/machine/bin/vms/solution.ini
__echo_run cp target/$MACHINE_BUNDLE "$MACHINE_HOME/machine/bundles"

echo "#################### Build and setup the adatper end ####################"

cd "$CURRENT_DIR"
if [[ $SKIP_SERVICES -eq 0 ]]; then
	__print_center "Archive and copy Predix Machine container to the target device" "#"
 	__echo_run ./scripts/predix_machine_setup.sh "$TEMP_APP" "0" "1"
else
	read -p "Enter the IP Address of your device(press enter if you want to copy to different directory on the host)> " TARGETDEVICEIP
	TARGETDEVICEIP=${TARGETDEVICEIP:localhost}
	read -p "Enter the Username on your device(this is the username which you use to ssh to the device> " TARGETDEVICEUSER
	read -p "Enter the Predix Machine Home Directry> " PREDIX_MACHINE_ROOT_DIR

	__echo_run cp "$CURRENT_DIR/../../target/$MACHINE_BUNDLE" "$MACHINE_HOME/machine/bundles"

	__echo_run scp "$CURRENT_DIR/../../target/$MACHINE_BUNDLE" $TARGETDEVICEUSER@$TARGETDEVICEIP:$PREDIX_MACHINE_ROOT_DIR/machine/bundles
	echo "Transferred Predix Machine bundle!" "#"
fi
