#!/bin/bash

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will perform actions around local-setup
#
localSetupLogDir="."


function run_mac_setup() {
	#get the url and branch of the requested repo from the version.json
	__readDependency "local-setup" LOCAL_SETUP_URL LOCAL_SETUP_BRANCH

  echo "Let's start by verifying that you have the required tools installed."
  read -p "Should we install the required tools if not already installed? ($TOOLS) > " -t 300 answer
  if [[ -z $answer ]]; then
      echo -n "Specify (yes/no)> "
      read answer
  fi
  if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
		if [[ $LOCAL_SETUP_URL == *"github.com"* ]]; then
			LOCAL_SETUP_URL="${LOCAL_SETUP_URL/github.com/raw.githubusercontent.com}"
		else
			if [[ $LOCAL_SETUP_URL == *"github.build"* ]]; then
				LOCAL_SETUP_URL="${LOCAL_SETUP_URL/github.com/PredixDev/raw}"
			fi
		fi
		SETUP_MAC="$LOCAL_SETUP_URL/$LOCAL_SETUP_BRANCH/setup-mac.sh"
		echo "SETUP_MAC=$SETUP_MAC"
    bash <(curl -s -L $SETUP_MAC) $TOOLS_SWITCHES
  fi
}

function __print_out_standard_usage
{
  echo -e "**************** Usage ***************************"
	echo -e "     ./$SCRIPT_NAME [ options ]\n"
  echo -e "     options are as below"
  echo "        [-b|          --branch]                        => Github Branch, default is master"
  echo "        [-cf|         --continue-from]                 => After passing -cf switch, add the switch from which you want to continue"
  echo "        [-skip-setup| --skip-setup]                    => Skip the installation of tools"
  echo "        [-o|          --override]                      => After passing -o switch, list the features you want to install"
  echo "        [-h|-?|--?|   --help]                          => Print usage"

	echo -e "     *** examples\n"
  echo -e "     ./$SCRIPT_NAME                                     => install all features"
  echo -e "     ./$SCRIPT_NAME --skip-setup                        => skip the installation of tools"
  echo -e "     ./$SCRIPT_NAME --continue-from -xxx                => start from the feature -xxx, skipping anything before that"
  echo -e "     ./$SCRIPT_NAME --override -yyy                     => only run the yyy service install feature"
  echo -e "**************************************************"
}

function __standard_mac_initialization() {
  echo ""
  echo "Welcome to the $APP_NAME Quick Start."
  __print_out_standard_usage
  echo "SKIP_SETUP            : $SKIP_SETUP"
  echo "BRANCH                : $BRANCH"
  echo "QUICKSTART_ARGS       : $QUICKSTART_ARGS"
  run_mac_setup
  echo ""
  echo "The required tools have been installed or you have chosen to not install them. Proceeding with the setting up of services and application."
  echo ""
  echo ""
}

function __echoAndRun() {
  echo $@
  $@
}

function __verifyAnswer() {
  if [[ -z $answer ]]; then
    echo -n "Specify (yes/no)> "
    read answer
  fi
  if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
    answer="y"
  else
    answer="n"
  fi
}



function __pause() {
	if [[ $SKIP_INTERACTIVE == 0 ]]; then
		read -n1 -r -p "Press any key to continue..."
	  echo ""
	fi
}
#	----------------------------------------------------------------
#	Function for echoing a command and then running it
#		Accepts any number of arguments:
#	----------------------------------------------------------------
__echo_run() {
  echo $@
  $@
  return $?
}



#	----------------------------------------------------------------
#	Function for checking the expected number of arguments
#		Accepts 4 argument:
#			string containing the expected number
#			string of the actual number of arguments
#			string explaining the expected arguments
#     string containing the root path of where the log will output
#	----------------------------------------------------------------
function validate_num_arguments
{
	if [[ "$#" -ne 4 ]] ; then

		ERRORMSG="__validate_num_arguments() - Expected (4), Actual($#) arguments. Expected in order: number of arguments, actual number of arguments, explaination of required arguments, path to where log will be generated"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$localSetupLogDir/localsetuplog.log"
		exit 1
	fi

	if [[ "$1" -ne "$2" ]]; then
		ERRORMSG="Expected ($1), Actual($2) arguments. $3"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$4/localsetuplog.log"
		exit 1
	fi
}

#Creating a timestamp for logging
timestamp() {
  date +"%Y-%m-%d  %H:%M:%S"
}

#	----------------------------------------------------------------
#	Function for appending to a logfile
#		Accepts 2 argument:
#			string content of the new line being appended to line matching pattern
#     string of where to generate the log
#	----------------------------------------------------------------
function append_new_line_log
{
	validate_num_arguments 2 $# "\"append_new_line_log()\" expected in order: String of the new line being appended, path of where to generate log" "$localSetupLogDir"
	echo "-->> $1"
	#echo "-->> $2"
	echo $(timestamp): " --- " "$1"  >> "$2/localsetup.log"
}

function getPredixScripts() {
  if [ ! -d "$PREDIX_SCRIPTS" ]; then
    echo "Cloning predix script repo ... $PREDIX_SCRIPTS_URL $PREDIX_SCRIPTS_BRANCH"
    git clone --depth 1 --branch $PREDIX_SCRIPTS_BRANCH $PREDIX_SCRIPTS_URL
  else
    echo "Predix scripts repo found reusing it..."
    cd $PREDIX_SCRIPTS
    git pull
    cd ..
  fi
}

function getCurrentRepo() {
  quickstartRootDir="$( pwd )/$PREDIX_SCRIPTS"
  cd $PREDIX_SCRIPTS
  source bash/scripts/files_helper_funcs.sh
  getGitRepo $REPO_NAME
  cd ..
}


#	----------------------------------------------------------------
#	Function for getting a gitRepo
#		Accepts 1 argument (+1 optional argument):
#			string of repo to clone, must be in version.json
#			boolean string indicating whether delete the dir
#  Returns:
#	----------------------------------------------------------------
function getGitRepo() {
	validate_num_arguments 1 $# "\"local-setup-funcs:getGitRepo\" Directory to clone to, optional arg whether to remove dir" "$localSetupLogDir"

	if [[ $2 == "" ]] || $2 == "false" || $2 == "FALSE" ]]; then
		rm -rf $1
	fi
	currentDir=$(pwd)
	echo $currentDir
	if [[ $currentDir/ == *"$1/"* ]]; then
		cd ..
		if [ -d "$1" ]; then
			append_new_line_log "copy $1 dir to.. $currentDir" "$localSetupLogDir"
			mkdir -p $currentDir/$1
			find $1/* -maxdepth 0 -type f -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp '{}' predix-scripts/$1 2>>/dev/null ';'
			find $1/.* -maxdepth 0 -type f -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp '{}' predix-scripts/$1 2>>/dev/null ';'
			find $1/* -maxdepth 0 -type d -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp -R '{}' predix-scripts/$1 ';'
			cd $currentDir
			return
		else
			cd ..
			pwd
			if [ -d "$1" ]; then
				append_new_line_log "copy $1 dir to... $currentDir" "$localSetupLogDir"
				mkdir -p $currentDir/$1
				find $1/* -maxdepth 0 -type f -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp '{}' $1/predix-scripts/$1 2>>/dev/null ';'
				find $1/.* -maxdepth 0 -type f -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp '{}' $1/predix-scripts/$1 2>>/dev/null ';'
				find $1/* -type d -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp -R '{}' $1/predix-scripts/$1 ';'
				cd $currentDir
				return
			else
				append_new_line_log "$1 dir not available to copy, will git clone" "$localSetupLogDir"
			fi
		fi
		cd ..
	fi

	#get using git, look in version.json to find the reponame and branch
	cd $currentDir
	getRepoURL $1 git_url ../version.json
	getRepoVersion $1 branch ../version.json
	if [ ! -n "$branch" ]; then
		branch="$BRANCH"
	fi
	if git clone -b "$branch" "$git_url" "$1"; then
		append_new_line_log "Successfully cloned \"$git_url\" and checkout the branch \"$branch\"" "$localSetupLogDir"
	else
		__error_exit "There was an error cloning the repo \"$1\". Is the repo listed in version.json?  Also, be sure to have permissions to the repo, or SSH keys created for your account" "$localSetupLogDir"
	fi
}

# method to fetch API KEY for artifactory
function fetchArtifactoryKey(){
	validate_num_arguments 0 $# "\"local-setup-funcs:getArtifactoryKey\" calls the artifactory with user credentails to get apikey" "$localSetupLogDir"
	echo "Apps and Services in the Predix Cloud need unique artifactory information"
	read -p "Enter your predix.io artifactory username >" INPUT
	export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"

	#echo "******************************"
	#echo "In the next step please enter the Apikey for the artifactory.To create a new apikey follow these steps"
	#echo "Login to artifactory, click on the left side Welcome <username>."
	#echo "This is open a User Profile page."
	#echo "Enter your current Password and click UnLock."
	#echo "The Api Key box will be popluated with the APIKey,then use clipboard icon to copy this apikey."
	#echo "******************************"
	#read -p "Enter your predix.io artifactory apikey >" INPUT
	#export ARTIFACTORY_APIKEY="${INPUT:-$ARTIFACTORY_APIKEY}"

	read -p "Enter your predix.io artifactory password >" -s INPUT
	ARTIFACTORY_PASSWORD="${INPUT:-$ARTIFACTORY_PASSWORD}"
	artifactoryKey=$( getArtifactoryKey "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
  #echo " fetching ARTIFACTORY KEY in first attempt"  $artifactoryKey
	if [[ -z "${artifactoryKey// }" ]]; then
		#echo "ARTIFACTORY KEY empty, attempting to create..."
		echo ""
		echo "artifactory apikey not found, will try to create one"
		artifactoryKey=$( postArtifactoryKey "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
		if [[ -z "${artifactoryKey// }" ]]; then
			echo ""
			echo "Artifactory apikey not created, perhaps you already have one. Please try your predix.io username and password again, maybe you mistyped it earlier."
			read -p "Enter your predix.io artifactory username >" INPUT
	    export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"
			read -p "Enter your predix.io artifactory password >" -s INPUT
			ARTIFACTORY_PASSWORD="${INPUT:-$ARTIFACTORY_PASSWORD}"
			artifactoryKey=$( getArtifactoryKey "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
		fi
	fi

	## 2 attempt report error
	if [[ -z "${artifactoryKey// }" ]]; then
		artifactoryKey="unknown"
		echo ""
		echo "ARTIFACTORY APIKEY is not set. Predix RPM package updates will not be fetched, but critical Dev Kit functionality will still work.  To try again later, re-run this script."
	fi
	echo ""
	echo "Artifactory Key is $artifactoryKey"
	export ARTIFACTORY_APIKEY=$artifactoryKey
}

function postArtifactoryKey() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey\" calls the artifactory with user credentails to get apikey" "$localSetupLogDir"
	source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
	responseCurl=`curl -X POST --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  apiKey=$( __jsonval "$responseCurl" "apiKey" )
	# if api key not found create one .
	echo "$apiKey"
}

function getArtifactoryKey() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey\" calls the artifactory with user credentails to get apikey" "$localSetupLogDir"
	source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
	responseCurl=`curl --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  apiKey=$( __jsonval "$responseCurl" "apiKey" )
	echo "$apiKey"
}
