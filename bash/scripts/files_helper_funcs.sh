#!/bin/bash
set -e
rootDir=$quickstartRootDir
logDir="$rootDir/log"

source "$rootDir/bash/scripts/error_handling_funcs.sh"

trap "trap_ctrlc" 2

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will perform File
# modification
#

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 4 argument:
#			string being replaced
#			string replacing the matching pattern
#			string of the filename
#     string of where to generate the log
#	----------------------------------------------------------------
function __find_and_replace
{
	__validate_num_arguments 4 $# "\"__find_and_replace()\" expected in order:  Pattern to find, String relacing the matching pattern, filename, path of where to generate log" "$logDir"
	#echo sed "s#$1#$2#" "$3"
	sed "s#$1#$2#" "$3" > "$3.tmp"
	if mv "$3.tmp" "$3"; then
		echo "Successfully ran sed command on file: \"$3\", replacing pattern: \"$1\", with: \"$2\""
	else
		__error_exit "Failed to modify the file: \"$3\"" "$4"
	fi
}


#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 4 argument:
#			string of the pattern
#			string content of the new line being appended to line matching pattern
#			string of the filename
#     string of where to generate the log
#	----------------------------------------------------------------
function __find_and_append_new_line
{
	__validate_num_arguments 4 $# "\"__find_and_append_new_line()\" expected in order:  Pattern to find, String of the new line being appended, filename, path of where to generate log" "$logDir"

	awk '/'"$1"'/{print $0 RS "'"$2"'";next}1' "$3" > "$3.tmp"

	#sed -e "/$1/a\\
	#$2" "$3" > "$3.tmp"
	if mv "$3.tmp" "$3"; then
		echo "Successfully ran AWK command on file: \"$3\", appending new line to line matching pattern: \"$1\", with: \"$2\""
	else
		__error_exit "Failed to modify the file: \"$3\"" "$4"
	fi
}

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 4 argument:
#			string being replaced
#			string replacing the matching pattern
#			string of the filename
#     string of where to generate the log
#	----------------------------------------------------------------
function __find_and_replace_string
{
	__validate_num_arguments 5 $# "\"__find_and_replace()\" expected in order:  Pattern to find, String relacing the matching pattern, filename, path of where to generate log" "$logDir"
	#echo sed "s#$1#$2#" "$3"
	sed "s#$1#$2#" "$3" > "$3.tmp"
	if mv "$3.tmp" "$5"; then
		echo "Successfully ran sed command on file: \"$3\", replacing pattern: \"$1\", with: \"$2\""
	else
		__error_exit "Failed to modify the file: \"$3\"" "$4"
	fi
}

#	----------------------------------------------------------------
#	Function for appending a header message to logfile
#		Accepts 3 argument:
#			string content of the new header being appended to line matching pattern
#			string containing the separater character
#     string of where to generate the log
#	----------------------------------------------------------------
function __append_new_head_log
{
	__validate_num_arguments 3 $# "\"__append_new_line_log()\" expected in order: String of the new line being appended, seperater char, path of where to generate log" "$logDir"
	__print_center "$1" "$2"
	echo $(timestamp): " --- " "$1"  >> "$3/quickstart.log"
}

#	----------------------------------------------------------------
#	Function for appending to a logfile
#		Accepts 2 argument:
#			string content of the new line being appended to line matching pattern
#     string of where to generate the log
#	----------------------------------------------------------------
function __append_new_line_log
{
	__validate_num_arguments 2 $# "\"__append_new_line_log()\" expected in order: String of the new line being appended, path of where to generate log" "$logDir"
	echo "-->> $1"
	echo $(timestamp): " --- " "$1"  >> "$2/quickstart.log"
}

#	----------------------------------------------------------------
#	Function for appending to a file
#		Accepts 2 argument:
#			string content of the new line being appended to line matching pattern
#			string of the filename
#	----------------------------------------------------------------
function __append_new_line
{
	__validate_num_arguments 2 $# "\"__append_new_line()\" expected in order: String of the new line being appended, filename" "$logDir"
	echo -e "$1" >> "$2"
}

#Creating a timestamp for logging
timestamp() {
  date +"%Y-%m-%d  %H:%M:%S"
}

function __checkoutTags
{
	#Checkout the tag if provided by user
	if [[ ( "$1" != "") ]]; then
		git tag
		reponame=$(echo "$1" | awk -F "/" '{print $NF}')
		echo "$reponame"

		repo_version="$(echo "$a" | sed -n "/$reponame/p" $rootDir/../../version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $NF}')"
		if [[ "$(git tag | grep "$repo_version" | head -n 1 | wc -l | awk '{$1=$1}{ print }')" == "1" ]]; then
	    git checkout tags/$repo_version
	  else
	    echo "No release tag version $repo_version found for $reponame"
	  fi
	fi
}

function getRepoURL {
	local  repoURLVar=$2
	reponame=$(echo "$1" | awk -F "/" '{print $NF}')
	echo reponame=$reponame
	url=$( jq -r --arg repo "$reponame" .dependencies[\$repo]  $3 | awk -F"#" '{print $1}')
	echo "url=$url"
	#url=$(echo "$a" | sed -n "/$reponame/p" $rootDir/../../version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $1}')
	eval $repoURLVar="'$url'"
}

function getRepoVersion {
	local  repoVersionVar=$2
	reponame=$(echo "$1" | awk -F "/" '{print $NF}')
	repoVersion=$( jq -r --arg repo "$reponame" .dependencies[\$repo]  $3 | awk -F"#" '{print $NF}')
	#repoVersion="$(echo "$a" | sed -n "/$reponame/p" $rootDir/../../version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $NF}')"
	eval $repoVersionVar="'$repoVersion'"
}

# 4 args: jsonPath, string value, JSON filename, log directory
function setJsonProperty {
  # __validate_num_arguments 4 $# "\"setJsonProperty()\" expected in order:  JSON path, string value, JSON filename, path of where to generate log" "$logDir"
  local _jsonPath=$1
  if jq '('$_jsonPath')="'$2'"' $3 > "$3.tmp"; then
    if mv "$3.tmp" "$3"; then
      echo "Successfully ran jq command on file: \"$3\", setting value: \"$1\" = \"$2\""
    else
      __error_exit "Failed to modify the file: \"$3\"" "$4"
      echo "error"
    fi
  else
    echo "Error running jq command on file: \"$3\", setting value: \"$1\" = \"$2\""
  fi
}
