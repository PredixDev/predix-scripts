#!/bin/bash
#This script verifies all the proxy settings for MAC using the proxies set
#for the environment variables, Maven and Docker
set -e

ProxyDir="$( pwd )"
export ProxyDir

#VERIFY_MAVEN_SETTINGS=0;

function usage() {
  echo
  echo Usage:
  echo $0 [--help] [--bash] [--maven] [--docker]
  echo
  echo "Options:"
  echo "    --help      Display this help message"
  echo "    --bash      Verify the proxy settings for bash environment variables"
  echo "    --maven     Verify the proxy settings for Maven (using the settings.xml file)"
  echo "    --docker    Verify the proxy settings for Docker (using the Docker Daemon tool)"
  echo
}

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

function verify_docker() {
  echo "Running docker pull hello-world"
  docker_command="docker pull hello-world";
  if $docker_command ; then
    echo
    echo "Docker verification -> Success"
    echo "Done"
  else
    echo
    echo "Docker verification -> Failed"
    echo "Please make sure you have started your Docker Daemon tool and if the proxies are configured"
  fi
}

function verify_bash() {
  if [[ -z "${HTTP_PROXY}" ]]; then
    echo "Proxies not set -> "
    echo
    echo "If needed, please run toggle_proxy.sh to enable/disable your proxies for Bash and Maven"
    echo "The toggle proxy script can be found in current directory or predix-scripts/bash/common/proxy"
    echo "./toggle-proxy.sh --enable"
    echo "OR"
    echo "./toggle-proxy.sh --disable"
  else
    echo "Proxies already set -> Success"
    echo "Done"
  fi
}

function guessProxy() {
  export GUESSED_PROXY_HOST=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f1`
  export GUESSED_PROXY_PORT=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f2`
}

function check_internet() {
  set +e
  echo "Checking proxy environment variables for internet access"
  curl "http://github.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy."
    echo
    echo "Please run toggle_proxy.sh to enable/disable your proxies for Bash and Maven"
    echo "./toggle-proxy.sh --enable"
    echo "OR"
    echo "./toggle-proxy.sh --disable"
    echo
    exit 1
  fi
  echo
  echo "Proxies setup for internet access -> Success"
  echo "Done"
  echo
  set -e
}

function run_default() {
  echo
  echo "--------------------------------------------------------"
  check_internet
  echo "--------------------------------------------------------"
  echo "Verifying proxy variables in bash profile"
  echo
  verify_bash
  echo
  echo "--------------------------------------------------------"
  echo "Verifying Maven"
  verify_maven ~/.m2/settings.xml
  echo
  #echo "--------------------------------------------------------"
  #echo "Verifying Docker"
  #verify_docker
  #echo
}

for arg in $@ ; do
  if [ "$arg" = "--help" ] ; then
    usage
    exit 0
  fi
done

#Switches
BASH=0
MAVEN=0
DOCKER=0

if [ -z "$1" ]; then
  run_default
else
  while [ ! -z "$1" ]; do
    [ "$1" == "--bash" ] && BASH=1
    [ "$1" == "--maven" ] && MAVEN=1
    [ "$1" == "--docker" ] && DOCKER=1
    shift
  done
fi

if [ $BASH -eq 1 ]; then
  echo
  echo "--------------------------------------------------------"
  check_internet
  echo "--------------------------------------------------------"
  echo "Verifying proxy variables in bash profile"
  echo
  verify_bash
  echo
fi

if [ $MAVEN -eq 1 ]; then
  echo "--------------------------------------------------------"
  echo "Verifying Maven"
  verify_maven ~/.m2/settings.xml
  echo
fi

if [ $DOCKER -eq 1 ]; then
  echo "--------------------------------------------------------"
  echo "Verifying Docker"
  verify_docker
  echo
fi
