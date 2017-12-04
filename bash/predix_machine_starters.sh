#!/bin/bash
set -e

function local_read_args() {
  while (( "$#" )); do
    opt="$1"
    case $opt in
        -h|-\?|--\?--help)
        echo -e "**************** Usage ***************************"
        echo -e "     ./$0 [ options ]\n"
        echo -e "     options are as below"
        echo "        [-maven-settings]               => Maven Settings file (provide full path)"
        echo "        [-sample-bundle]                => Sample Bundle name"
        echo "        [-machine-version]              => Predix Machine Version"
        echo "        [-h|-?|--?|   --help]           => Print usage"
        exit
        ;;
      -maven-settings)
        MAVEN_SETTINGS_FILE="$2"
        if [ "$MAVEN_SETTINGS_FILE" == "" ]; then
            printf 'ERROR: "-maven-settings" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
      -machine-version)
        MACHINE_VERSION="$2"
        if [ "$MACHINE_VERSION" == "" ]; then
            printf 'ERROR: "-machine-version" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
			-sample-bundle)
        SAMPLE_BUNDLE_NAME="$2"
        if [ "$SAMPLE_BUNDLE_NAME" == "" ]; then
            printf 'ERROR: "-sample-bundle" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
      *)
        QUICKSTART_ARGS+=" $1"
        #echo $1
        ;;
    esac
    shift
  done
}

PARAMS="$@"
if [[ "$PARAMS" == "" ]]; then
  PARAMS="-h"
fi
local_read_args $PARAMS

if [[ "$MAVEN_SETTINGS_FILE" == "" ]]; then
  MAVEN_SETTINGS_FILE="~/.m2/settings.xml"
fi
#Download the Predix Machine SDK
PREDIX_MACHINE_SDK="predixmachinesdk-$MACHINE_VERSION"
rm -rf $PREDIX_MACHINE_SDK
mvn org.apache.maven.plugins:maven-dependency-plugin:2.6:copy -Dartifact=predix-machine-package:predixmachinesdk:$MACHINE_VERSION:zip -DoutputDirectory=. -s ~/.m2/settings_external.xml

#Download the pre-built machine container
PREDIX_MACHINE_CONTAINER="PredixMachineEdgeStarter-$MACHINE_VERSION"
rm -rf $PREDIX_MACHINE_CONTAINER
mvn org.apache.maven.plugins:maven-dependency-plugin:2.6:copy -Dartifact=predix-machine-containers:PredixMachineEdgeStarter:$MACHINE_VERSION:zip -DoutputDirectory=. -s ~/.m2/settings_external.xml

unzip $PREDIX_MACHINE_SDK.zip

unzip $PREDIX_MACHINE_CONTAINER.zip -d $PREDIX_MACHINE_CONTAINER

unzip $PREDIX_MACHINE_SDK/samples/sample-apps.zip -d $PREDIX_MACHINE_SDK/samples
mvn clean install -f $PREDIX_MACHINE_SDK/samples/sample/pom.xml -DoutputDirectory=.

cp -rf $PREDIX_MACHINE_SDK/samples/sample/configuration/machine/* $PREDIX_MACHINE_CONTAINER/configuration/machine

if [[ "$SAMPLE_BUNDLE_NAME" == "all" ]]; then
  for file in $(find $PREDIX_MACHINE_SDK/samples/sample -name "*.jar"); do
    cp $file $PREDIX_MACHINE_CONTAINER/machine/bundles
    BUNDLE_JAR_NAME=$(echo "$file" | awk -F"/" '{print $6}')
    SAMPLE_BUNDLES="$SAMPLE_BUNDLES<bundle><name>$BUNDLE_JAR_NAME</name></bundle>"
  done
else
  cp $PREDIX_MACHINE_SDK/samples/sample/$SAMPLE_BUNDLE_NAME/target/*.jar $PREDIX_MACHINE_CONTAINER/machine/bundles
  SAMPLE_BUNDLES="<bundle><name>com.ge.dspmicro.$SAMPLE_BUNDLE_NAME-$MACHINE_VERSION.jar</name></bundle>"
fi

cat << EOF > $PREDIX_MACHINE_CONTAINER/machine/bin/vms/solution.ini
<?xml version="1.0" encoding="UTF-8"?>
<main>
    <section>
        <name>Section_8_Start</name>
        <level>8</level>
        <strategy>
            <action>i -f -S </action>
        </strategy>
        $SAMPLE_BUNDLES
    </section>
</main>
EOF
