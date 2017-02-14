#!/bin/bash

function verifymvnproxy() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom 2>&1 | grep "nodename nor servname provided" &>/dev/null
  echo $?
}

function verifymvncreds() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom 2>&1 | grep "ReasonPhrase:Unauthorized" &>/dev/null
  echo $?
}

function assertmvn() {
  if [[ $(verifymvnproxy) -eq 0 ]]; then
    echo "Unable to connect to maven repository at https://artifactory.predix.io"
    echo "Verify that you are connected to the internet."
    echo "If you are behind a corporate proxy, verify that you have entered valid proxy settings in your maven settings file."
    echo "The maven settings file is located at ~/.m2/settings.xml."
    exit 1
  fi
  if [[ $(verifymvncreds) -eq 0 ]]; then
    echo "Failed to fetch artifact from https://artifactory.predix.io"
    echo "Verify that you have provided a valid username/password in your maven settings file."
    echo "The maven settings file is located at ~/.m2/settings.xml."
    exit 1
  fi
}

function checkmvnsettings() {
  local mvn_setting_file=$1

  if [ ! -f "$mvn_setting_file" ]; then
    echo "Maven setting File missing at $mvn_setting_file location"
    echo "Please configure your maven settings file to continue"
    exit 1
  fi
  echo "Using Maven settings file from $mvn_setting_file"
  if [[ $(verifymvnsettings $mvn_setting_file ) -eq 0 ]]; then
    echo "Failed to fetch artifact from reposistory"
    echo "Verify that you have provided a valid a reposistory url and or username/password in your maven settings file."
    echo "The maven settings file is located at $mvn_setting_file."
    exit 1
  fi

}

function verifymvnsettings() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  mvn -s $1 org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom 2>&1 | grep "ReasonPhrase:Unauthorized" &>/dev/null
  echo $?
}
