#!/bin/bash

set -e
BRANCH="master"
SKIP_SETUP=false

if [[ $1 == "--skip-setup" ]]; then
  SKIP_SETUP=true
  shift
fi

SETUP_MAC="https://raw.githubusercontent.com/PredixDev/local-setup/$BRANCH/setup-mac.sh"
PREDIX_SCRIPT_DIR_NAME=predix-scripts
PREDIX_SCRIPT_REPO=https://github.com/PredixDev/$PREDIX_SCRIPT_DIR_NAME.git

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

function run_setup() {
  check_internet
  bash <(curl -s -L "$SETUP_MAC") --git --cf --nodejs --maven
}

function git_clone_repo() {
  echo ""
  echo "Cloning predix script repo ..."
  git clone $PREDIX_SCRIPT_REPO
}

if $SKIP_SETUP; then
  check_internet
else
    echo "Welcome to the Predix Build An Application Quick Start."
    run_setup
    echo ""
    echo "The required tools have been installed. Proceed with the setting up services and application."
    echo ""
    echo ""
fi

git_clone_repo
$PREDIX_SCRIPT_DIR_NAME/bash/quickstart.sh $@
