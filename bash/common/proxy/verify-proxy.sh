#!/bin/sh

#This script verifies all the proxy settings for MAC using the proxies set
#for the environment variables, Maven and Docker

set -e

usage() {
  echo
  echo Usage:
  echo
  echo Options:
  echo "    --help      Display this help message"
}

verify_maven(){
  #MAVEN_SETTINGS_FILE="~/.m2/settings.xml"
  #checkmvnsettings $MAVEN_SETTINGS_FILE
  #assertmvn $MAVEN_SETTINGS_FILE

  rm -f ~/.m2/repository/com/ge/predix/solsvc/ext-api/2.0.5/ext-api-2.0.5.pom
  mvn_command="mvn org.apache.maven.plugins:maven-dependency-plugin:2.10:get -DrepoId=predix.repo -Dartifact=com.ge.predix.solsvc:ext-api:2.0.5:pom"

  if $mvn_command ; then
    echo
    echo "Maven verification -> Success"
    echo "Done"
  else
    echo
    echo "Maven verification -> Failed"
    echo "Unable to connect to maven repository at https://artifactory.predix.io"
    echo "Verify that you are connected to the internet."
    echo "If you are behind a corporate proxy, verify that you have entered valid proxy settings in your maven settings file."
    echo "The maven settings file is located at ~/.m2/settings.xml."
  fi
}

verify_docker(){
  echo "Running docker pull hello-world"
  command="docker pull hello-world";
  if $command ; then
    echo
    echo "Docker verification -> Success"
    echo "Done"
  else
    echo
    echo "Docker verification -> Failed"
    echo "Please make sure you have started your Docker Daemon tool"
    echo "Please make sure proxies are set in the Docker Daemon tool"
  fi
}

verify_bash() {
  if [[ -z "${HTTP_PROXY}" ]]; then
    echo "Proxy not set -> Failed"
  else
    echo "Proxy already set -> Success"
    echo "Done"
  fi
}

guessProxy() {
  export GUESSED_PROXY_HOST=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f1`
  export GUESSED_PROXY_PORT=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f2`
}

function check_internet() {
  set +e
  echo "Checking internet connection..."
  curl "http://github.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy."
    echo
    echo "Please run toggle_proxy.sh to enable/disable your proxies for Bash and Maven"
    echo "./toggle-proxy.sh --enable"
    echo "OR"
    echo "./toggle-proxy.sh --disable"
    echo
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

for arg in $@ ; do
  if [ "$arg" = "--help" ] ; then
    usage
    exit 0
  fi
done

echo
echo "------------------------------------------------------"
check_internet

echo "------------------------------------------------------"
echo "Verifying bash proxy variables"
echo
verify_bash
echo

echo "------------------------------------------------------"
echo "Verifying Maven"
echo
verify_maven
echo

echo "------------------------------------------------------"
echo "Verifying Docker"
echo
verify_docker
echo
