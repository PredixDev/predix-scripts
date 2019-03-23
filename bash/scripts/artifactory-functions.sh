#!/bin/bash

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will perform actions around local-setup
#
localSetupLogDir="."

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

function getjson {
    	validate_num_arguments 2 $# "\"curl_helper_funcs:__jsonval\" expected in order: String of JSON, String of property to look for" "$logDir"
    	temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
    	echo ${temp##*|}
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

# method to fetch API KEY for artifactory
function fetchArtifactoryKey2(){
	validate_num_arguments 0 $# "\"local-setup-funcs:getArtifactoryKey2\" calls artifactory with user credentails to get API Key" "$localSetupLogDir"
	read -p "Enter your predix.io cloud username (usually your email address)>" INPUT
	export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"

	if [[ $ARTIFACTORY_USERNAME = *"ge.com"* ]]; then
		echo "************************************************************************************************************************"
		echo "In the next step please enter the API Key for Artifactory. To retrieve your API Key follow these steps"
		echo "Login to artifactory at https://artifactory.predix.io.  (if you are a @ge.com user, please click on the SAML SSO link)"
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
		artifactoryKey=$( getArtifactoryKey2 "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
	  	#echo " fetching ARTIFACTORY KEY in first attempt"  $artifactoryKey
		if [[ -z "${artifactoryKey// }" ]]; then
			#echo "ARTIFACTORY KEY empty, attempting to create..."
			echo ""
			echo "artifactory API Key not found, will try to create one"
			artifactoryKey=$( postArtifactoryKey2 "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
			if [[ -z "${artifactoryKey// }" ]]; then
				echo ""
				echo "Artifactory API Key not created, perhaps you already have one. Please try your predix.io username and password again, maybe you mistyped it earlier."
				read -p "Enter your predix.io artifactory username >" INPUT
		    export ARTIFACTORY_USERNAME="${INPUT:-$ARTIFACTORY_USERNAME}"
				read -p "Enter your predix.io artifactory password >" -s INPUT
				ARTIFACTORY_PASSWORD="${INPUT:-$ARTIFACTORY_PASSWORD}"
				artifactoryKey=$( getArtifactoryKey2 "$ARTIFACTORY_USERNAME" "$ARTIFACTORY_PASSWORD" )
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
	echo "Exporting Artifactory environment variables"
	echo "Artifactory ID is set to - $ARTIFACTORY_ID"
	echo "Artifactory username is set to - $ARTIFACTORY_USERNAME"
	echo "Artifactory API key is set to - $ARTIFACTORY_APIKEY"
	echo
	echo "Artifactory username $ARTIFACTORY_USERNAME with API Key $ARTIFACTORY_APIKEY" >> summary.txt

	# Checking if maven settings file exitsts
	if [[ -e ~/.m2/settings.xml ]]; then
		echo "We found a maven settings file on your machine at ~/.m2/settings.xml"
		echo -n "Do you want to add these credentials to your maven settings file (y/n) > "
		echo "Please Note -  This will overwrite the entire servers section in your ~/.m2/settings.xml file"
		read answer
		echo
		if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
			echo "Setting the Artifactory credentials in the maven settings.xml file"
			addApiKeytoMaven2
		else
			echo "Maven settings file (~/.m2/settings.xml) not updated"
			echo
		fi
	else
		echo "Maven settings file does not exist. To save time in future, you may store your Artifactory key there in the following location : (~/.m2/settings.xml)"
		echo "An example file is located at https://github.com/PredixDev/predix-rmd-ref-app/blob/master/docs/settings.xml"
		echo
	fi
}

function postArtifactoryKey2() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey2\" calls the artifactory with user credentails to get API Key" "$localSetupLogDir"
	#source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
	responseCurl=`curl -X POST --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  	apiKey=$( getjson "$responseCurl" "apiKey" )
	# if api key not found create one .
	echo $apiKey
}

function getArtifactoryKey2() {
	#this function cannot echo things otherwise it will get assigned to the calling variable
	validate_num_arguments 2 $# "\"local-setup-funcs:getArtifactoryKey2\" calls the artifactory with user credentails to get API Key" "$localSetupLogDir"
	#source bash/scripts/curl_helper_funcs.sh
	ARTIFACTORY_BASIC_AUTH=$(echo -ne $1:$2 | base64)
 	responseCurl=`curl --silent "https://artifactory.predix.io/artifactory/api/security/apiKey" -H "Authorization: Basic $ARTIFACTORY_BASIC_AUTH" -H "Content-Type: application/x-www-form-urlencoded"`
  	apiKey=$( getjson "$responseCurl" "apiKey" )
  	echo $apiKey
}

function addApiKeytoMaven2() {
  echo "ID = $ARTIFACTORY_ID"
	echo "Username = $ARTIFACTORY_USERNAME"
	echo "Password = $ARTIFACTORY_APIKEY"

	XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/scripts/setServerInMaven.xsl"
	curl -s -O $XSL_URL
	if [[ -e ~/.m2/settings.xml && -e setServerInMaven.xsl ]] ; then
    		echo "Making a backup of ~/.m2/settings.xml file and storing it as ~/.m2/settings.xml.orig"
		echo "You may use this file to retrieve any server specific data that the script overwrites"
		echo
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

function getCurlArtifactory2() {
	validate_num_arguments 1 $# "\"local-setup-funcs:getCurlArtifactory2\" calls the artifactory with ARTIFACT_URL, USERNAME and API_KEY to curl the artifact" "$localSetupLogDir"
	ARTIFACT_URL=$1

	if [[ -z $ARTIFACTORY_USERNAME && -z $ARTIFACTORY_APIKEY ]]; then
		echo
		echo "Artifactory Credentials not set in environment variables"
		echo
		if [[ -e ~/.m2/settings.xml ]]; then
			echo "Found a maven settings file on your machine at ~/.m2/settings.xml"
			echo "If you have run this script before, you may have saved your artifactory API key in the ~/.m2/settings.xml"
			echo -n "Would you like to use artifactory credentials from maven settings file (~/.m2/settings.xml) (y/n) > "
			read answer
			echo
			if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
				echo "Reading ~/.m2/settings.xml"
				getArtifactoryFromMaven2 ~/.m2/settings.xml
			else
				echo "Calling fetchApiKey"
				fetchArtifactoryKey2
			fi
		else
			echo "Did not find a maven settings file on your machine at ~/.m2/settings.xml, calling fetchApiKey"
			fetchArtifactoryKey2
		fi
	fi
	echo "Downloading Artifact using getCurlArtifactory"
	RESULT=$(curl -u $ARTIFACTORY_USERNAME:$ARTIFACTORY_APIKEY $ARTIFACT_URL -O)
	if [[ -n $RESULT ]]; then
		echo "Curl to artifact URL failed"
		echo "Please check the ARTIFACT_URL, ARTIFACTORY_USERNAME, AND ARTIFACTORY_APIKEY"
	fi
}

function getArtifactoryFromMaven2(){
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
				# for word in $USERNAME
				# do
				# 	echo $word
				# 	#echo "Id = $ID"
				# 	#echo "User = $USERNAME"
				# 	#echo "Password/API Key = $PASSWORD"
				# done
				ID_Arrays=($ID)
				User_Array=($USERNAME)
				PASSWD_ARRAY=($PASSWORD)
				len=${#ID_Arrays[@]}

				if [[ $len -eq 1 ]]; then
					echo "Server Id = ${ID_Arrays[0]}"
					echo "Username = ${User_Array[0]}"
					echo "Password/API Key = ${PASSWD_ARRAY[0]}"
					echo
				else
					for (( i=0; i<${len}; i++ ));
					do
						echo "Option $i:"
					  echo "Server Id = ${ID_Arrays[$i]}"
						echo "Username = ${User_Array[$i]}"
						echo "Password/API Key = ${PASSWD_ARRAY[$i]}"
						echo
					done
				fi

				echo "Please choose Yes to use one of these credentials"
				echo "Please choose No to fetch new API Key for your predix account"
				echo -n "Please approve to use these Artifactory credentials (y/n) > "
				read answer
				echo
				if [[ ${answer:0:1} == "y" ]] || [[ ${answer:0:1} == "Y" ]]; then
					if [[ $len -eq 1 ]]; then
						option=0
					else
						echo -n "Please choose which credentials option you would like to use > "
						read option
					fi
					echo
					export ARTIFACTORY_USERNAME=${User_Array[$option]}
					export ARTIFACTORY_APIKEY=${PASSWD_ARRAY[$option]}
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
		fetchArtifactoryKey2
	fi
}

