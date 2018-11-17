#!/bin/bash

function verifymvnproxy_success() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  export command=$(mvn -B org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom -s $1 2>&1 | grep "SUCCESS")
  if [ ! -z "$command" ]; then
    # Error found
    export VERIFY_MAVEN_PROXY_SUCCESS=0
  else
    # No Error found - Success
    export VERIFY_MAVEN_PROXY_SUCCESS=1
  fi
}

function verifymvnproxy() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  echo "mvn -B org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom -s $1"
  export command=$(mvn -B org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom -s $1 2>&1 | grep "Could not transfer artifact")
  if [ ! -z "$command" ]; then
    # Error found
    export VERIFY_MAVEN_PROXY=0
  else
    # No Error found - Success
    export VERIFY_MAVEN_PROXY=1
  fi
}

function verifymvncreds() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  export command=$(mvn -B org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom -s $1 2>&1 | grep "ReasonPhrase:Unauthorized")
  if [ ! -z "$command" ]; then
    # Error found
    export VERIFY_MAVEN_CREDS=0
  else
    # No Error found - Success
    export VERIFY_MAVEN_CREDS=1
  fi
}

function verifymvnsettings() {
  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom &>/dev/null
  export command=$(mvn -B -s $1 org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom 2>&1 | grep "ReasonPhrase:Unauthorized")
  if [ ! -z "$command" ]; then
    # Error found
    export VERIFY_MAVEN_SETTINGS=0
  else
    # No Error found - Success
    export VERIFY_MAVEN_SETTINGS=1
  fi
}

function assertmvn() {
  local mvn_setting_file=$1
  verifymvnproxy $mvn_setting_file
  if [ $VERIFY_MAVEN_PROXY -eq 0 ]; then
    echo ""
    echo "Unable to connect to maven repository at https://artifactory.predix.io"
    echo "Verify that you are connected to the internet."
    echo "If you are behind a corporate proxy, verify that you have entered valid proxy settings in your maven settings file."
    echo "The maven settings file is located at ~/.m2/settings.xml."
  fi
  verifymvncreds $mvn_setting_file
  if [ $VERIFY_MAVEN_CREDS -eq 0 ]; then
    echo ""
    echo "Failed to fetch artifact from https://artifactory.predix.io"
    echo "Verify that you have provided a valid username/password in your maven settings file."
    echo "The maven settings file is located at ~/.m2/settings.xml."
  fi
  verifymvnproxy_success $mvn_setting_file
  if [ $VERIFY_MAVEN_PROXY_SUCCESS -eq 0 ]; then
    echo
    echo "Maven verification -> Success"
    echo "Done"
  fi
}

function checkmvnsettings() {
  local mvn_setting_file=$1

  if [ ! -f $mvn_setting_file ]; then
    echo "Maven setting File missing at $mvn_setting_file location."
    echo "Please configure your maven settings file to continue."
    echo "Detailed instructions are in tutorial at: https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1560"
  fi
  echo "Using Maven settings file from $mvn_setting_file"
  verifymvnsettings $mvn_setting_file
  if [ $VERIFY_MAVEN_SETTINGS -eq 0 ]; then
    echo ""
    echo "Failed to fetch artifact from reposistory"
    echo "Verify that you have provided a valid a repository url and or username/encrypted password in your maven settings file."
    echo "The maven settings file is located at $mvn_setting_file."
    echo "Detailed instructions are in tutorial at: https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1560"
  fi
}

function verify_maven() {
  echo "Checking if project contains a pom.xml file"
  if [ -e "pom.xml" ]; then
    checkmvnsettings $1
    assertmvn $1
  else
    echo
    echo "Maven verification not needed as there is no pom.xml file"
    echo "Done"
  fi 
}
