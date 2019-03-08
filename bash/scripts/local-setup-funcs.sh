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

  if [[ "$TOOLS" != "" ]]; then
	  echo "Let's start by verifying that you have the required tools installed."
	  read -p "Should we install the required tools if not already installed? ($TOOLS) > " -t 300 answer
	  if [[ -z $answer ]]; then
	      echo -n "Specify (yes/no)> "
	      read answer
	  fi
	  if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
	    if [[ $LOCAL_SETUP_URL == *"github.com"* ]]; then
	      LOCAL_SETUP_URL="${LOCAL_SETUP_URL/github.com/raw.githubusercontent.com}"
	      echo "LOCAL_SETUP_URL=$LOCAL_SETUP_URL"
	    else
	      if [[ $LOCAL_SETUP_URL == *"github.build"* ]]; then
		raw="raw/adoption"
		LOCAL_SETUP_URL="${LOCAL_SETUP_URL/adoption/$raw}"
		echo "LOCAL_SETUP_URL=$LOCAL_SETUP_URL"
	      fi
	    fi
	    SETUP_MAC="$LOCAL_SETUP_URL/$LOCAL_SETUP_BRANCH/setup-mac.sh"
	    echo "SETUP_MAC=$SETUP_MAC"
	    getUsingCurl $SETUP_MAC
	    chmod +x setup-mac.sh
	    ./setup-mac.sh $TOOLS_SWITCHES
	    #bash <(curl -s -L $SETUP_MAC) $TOOLS_SWITCHES
	  fi
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
    if [[ -n $GITHUB_BUILD_TOKEN && $VERSION_JSON_URL = *"github.build.ge"* ]]; then
			PREDIX_SCRIPTS_URL=https://$GITHUB_BUILD_TOKEN@$(echo "$PREDIX_SCRIPTS_URL" | awk -F"//" '{print $2}')
		fi
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
#		Accepts 1 argument (+2 optional argument):
#			string of repo to clone, must be in version.json
#			boolean string indicating whether to keep existing dir
#  Returns:
#	----------------------------------------------------------------
function getGitRepo() {
	# validate_num_arguments 1 $# "\"local-setup-funcs:getGitRepo\" Directory to clone to, optional arg whether to remove dir" "$localSetupLogDir"

	if [[ $2 != "true" && $2 != "TRUE" ]]; then
    echo "Deleting existing directory: $1"
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
				find $1/* -maxdepth 0 -type d -not \( -path $1/predix-scripts -prune \) -not \( -path $1/.git -prune \) -exec cp -R '{}' $1/predix-scripts/$1 ';'
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
	if [[ -n $GITHUB_BUILD_TOKEN && $git_url = *"github.build.ge"* ]]; then
		echo "adding GITHUB_BUILD_TOKEN"
		git_url=https://$GITHUB_BUILD_TOKEN@$(echo "$git_url" | awk -F"//" '{print $2}')
	fi
	echo "Cloning $1 repo ... $git_url $branch"
	if git clone --depth 1 -b "$branch" "$git_url" "$1"; then
		append_new_line_log "Successfully cloned \"$git_url\" and checkout the branch \"$branch\"" "$localSetupLogDir"
	else
		__error_exit "There was an error cloning the repo \"$1\". Is the repo listed in version.json?  Also, be sure to have permissions to the repo, or SSH keys created for your account" "$localSetupLogDir"
	fi
}

# method to fetch API KEY for artifactory
function fetchArtifactoryKey(){
	validate_num_arguments 0 $# "\"local-setup-funcs:getArtifactoryKey\" calls artifactory with user credentails to get API Key" "$localSetupLogDir"
	read -p "Enter your predix.io cloud username (usually your email address)>" INPUT
	export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"

	if [[ $ARTIFACTORY_USERNAME = *"ge.com"* ]]; then
		echo "************************************************************************************************************************"
		echo "In the next step please enter the API Key for Artifactory. To retrieve your API Key follow these steps"
		echo "Login to artifactory.  (if you are a @ge.com user, please click on the SAML SSO link)"
		echo "Click on your User Profile <username>."
		echo "Enter your current Password and click UnLock."
		echo "The API Key box will be populated, then use clipboard icon to copy this API Key."
		echo "************************************************************************************************************************"
		read -p "Enter your predix artifactory username (e.g. your SSO)>" INPUT
		export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"
		read -p "Enter your predix.io artifactory API Key>" -s INPUT
		export ARTIFACTORY_APIKEY="${INPUT:-$ARTIFACTORY_APIKEY}"
		export ARTIFACTORY_ID="predix.repo"
	else
		read -p "Enter your predix.io artifactory password >" -s INPUT
		ARTIFACTORY_PASSWORD="${INPUT:-$ARTIFACTORY_PASSWORD}"
		artifactoryKey=$( getArtifactoryKey "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
	  	#echo " fetching ARTIFACTORY KEY in first attempt"  $artifactoryKey
		if [[ -z "${artifactoryKey// }" ]]; then
			#echo "ARTIFACTORY KEY empty, attempting to create..."
			echo ""
			echo "artifactory API Key not found, will try to create one"
			artifactoryKey=$( postArtifactoryKey "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
			if [[ -z "${artifactoryKey// }" ]]; then
				echo ""
				echo "Artifactory API Key not created, perhaps you already have one. Please try your predix.io username and password again, maybe you mistyped it earlier."
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
		export ARTIFACTORY_ID="predix.repo"
		export ARTIFACTORY_APIKEY=$artifactoryKey
	fi

	echo
	echo
	echo "Artifactory ID is set to - $ARTIFACTORY_ID"
	echo "Artifactory username is set to - $ARTIFACTORY_USERNAME"
	echo "Artifactory API key is set to - $ARTIFACTORY_APIKEY"
	echo
	echo "Artifactory username $ARTIFACTORY_USERNAME with API Key $ARTIFACTORY_APIKEY" >> summary.txt

	# Checking if maven settings file exitsts
	if [[ -e ~/.m2/settings.xml ]]; then
		echo "We found a maven settings file on your machine at ~/.m2/settings.xml"
		echo -n "Do you want to add these credentials to your maven settings file (y/n) > "
		read answer
		echo
		if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
			echo "Setting the Artifactory credentials in the maven settings.xml file"
			addApiKeytoMaven
		else
			echo "Maven settings file (~/.m2/settings.xml) not updated"
			echo
		fi
	else
		echo "Maven settings file does not exist"
		echo "We suggest adding one later for future reference in the following location : (~/.m2/settings.xml)"
		echo
	fi
}

function postArtifactoryKey() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey\" calls the artifactory with user credentails to get API Key" "$localSetupLogDir"
	#source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
	responseCurl=`curl -X POST --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  	apiKey=$( getjson "$responseCurl" "apiKey" )
	# if api key not found create one .
	echo $apiKey
}

function getArtifactoryKey() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey\" calls the artifactory with user credentails to get API Key" "$localSetupLogDir"
	#source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
 	responseCurl=`curl --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  	apiKey=$( getjson "$responseCurl" "apiKey" )
  	echo $apiKey
}

function getjson {
    	validate_num_arguments 2 $# "\"curl_helper_funcs:__jsonval\" expected in order: String of JSON, String of property to look for" "$logDir"
    	temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
    	echo ${temp##*|}
}

function addApiKeytoMaven() {
  echo "ID = $ARTIFACTORY_ID"
	echo "Username = $ARTIFACTORY_USERNAME"
	echo "Password = $ARTIFACTORY_APIKEY"

	XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/setServerInMaven.xsl"
	curl -s -O $XSL_URL
	if [[ -e ~/.m2/settings.xml && -e setServerInMaven.xsl ]] ; then
    		cp ~/.m2/settings.xml ~/.m2/settings.xml.orig
    		xsltproc --stringparam server-id $ARTIFACTORY_ID \
         	--stringparam server-username $ARTIFACTORY_USERNAME \
         	--stringparam server-password $ARTIFACTORY_APIKEY \
         	setServerInMaven.xsl ~/.m2/settings.xml.orig > ~/.m2/settings.xml.new

    		mv -f ~/.m2/settings.xml.new ~/.m2/settings.xml
    	echo
    	echo "Done."
	echo "Successfully set artifactory credentials in maven settings.xml file"
	echo
  	else
    		echo
    		echo "Could not find settings.xml in directory ./m2"
    		echo "OR"
    		echo "Could not find setServerInMaven.xsl"
    		echo "Failed: Artifactory credentials not set"
  	fi
}

function getCurlArtifactory() {
	validate_num_arguments 1 $# "\"local-setup-funcs:getCurlArtifactory\" calls the artifactory with ARTIFACT_URL, USERNAME and API_KEY to curl the artifact" "$localSetupLogDir"
	ARTIFACT_URL=$1

	if [[ -z $ARTIFACTORY_USERNAME && -z $ARTIFACTORY_APIKEY ]]; then
		echo
		echo "Artifactory Credentials not set in environment variables"
		echo -n "Would you like to extract artifactory credentials from maven settings file (~/.m2/settings.xml) (y/n) > "
		read answer
		echo
		if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
			echo "Reading ~/.m2/settings.xml"
			getArtifactoryFromMaven ~/.m2/settings.xml
		else
			echo "Calling fetchApiKey"
			fetchArtifactoryKey
		fi
	fi
	echo "Downloading Artifact using getCurlArtifactory"
	RESULT=$(curl -u $ARTIFACTORY_USERNAME:$ARTIFACTORY_APIKEY $ARTIFACT_URL -O)
	if [[ -n $RESULT ]]; then
		echo "Curl to artifact URL failed"
		echo "Please check the ARTIFACT_URL, ARTIFACTORY_USERNAME, AND ARTIFACTORY_APIKEY"
	fi
}

function getArtifactoryFromMaven(){
	MAVEN_SETTINGS_FILE=$1
	FETCH_FLAG=0;

	if [[ -e $MAVEN_SETTINGS_FILE ]]; then
		command=$(sed -n '/<server/,/<\/server/p' $MAVEN_SETTINGS_FILE)
		if [[ -n $command ]]; then
			sed -n '/<server/,/<\/server/p' $MAVEN_SETTINGS_FILE > tmp.xml
			ID=$(sed  -n 's/.*<id>\(.*\)<\/id>/\1/p' tmp.xml)
			USERNAME=$(sed  -n 's/.*<username>\(.*\)<\/username>/\1/p' tmp.xml)
			PASSWORD=$(sed  -n 's/.*<password>\(.*\)<\/password>/\1/p' tmp.xml)

			sed -n '/<repository/,/<\/repository/p' $MAVEN_SETTINGS_FILE > repos.xml
			var=$(cat repos.xml | grep https://artifactory.predix.io/artifactory/PREDIX-EXT)
			if [[ $var = *"https://artifactory.predix.io/artifactory/PREDIX-EXT"* ]]; then
				echo
				echo "Id = $ID"
				echo "User = $USERNAME"
				echo "Password/API Key = $PASSWORD"
				echo
				echo "Please choose Yes to use these credentials"
				echo "Please choose No to fetch new API Key for your predix account"
				echo -n "Please approve to use these Artifactory credentials (y/n) > "
				read answer
				echo
				if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
					export ARTIFACTORY_USERNAME=$USERNAME
					export ARTIFACTORY_APIKEY=$PASSWORD
					echo "Artifactory username is set to - $ARTIFACTORY_USERNAME"
					echo "Artifactory API Key is set to - $ARTIFACTORY_APIKEY"
					echo
				else
					FETCH_FLAG=1
				fi
				rm -rf repos.xml
				rm -rf tmp.txt
			else
				echo
				echo "Repository settings not set in Maven settings file $MAVEN_SETTINGS_FILE"
				echo "The script is looking for the following in the $MAVEN_SETTINGS_FILE"
				echo "<id>predix.repo</id>"
				echo "<url>https://artifactory.predix.io/artifactory/PREDIX-EXT</url>"
				echo
				FETCH_FLAG=1
			fi
		else
			echo "Could not find server section in the maven settings file $MAVEN_SETTINGS_FILE"
			FETCH_FLAG=1
		fi
	else
		echo "Maven settings file $MAVEN_SETTINGS_FILE could not be found"
		FETCH_FLAG=1
	fi

	if [[ 1 -eq $FETCH_FLAG ]]; then
		echo "Fetching Artifactory API key"
		fetchArtifactoryKey
	fi
}
