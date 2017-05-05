#!/bin/bash
set -e

rootDir=$quickstartRootDir
logDir="$rootDir/log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will all for error handling
#

# ********************************** HELPER FUNCTIONS **********************************
#

#	----------------------------------------------------------------
#	Function to print a text in the center of the line
#		Accepts 2 argument:
#			string containing descriptive message
#     string containing character to fill before and after the message
#	----------------------------------------------------------------
__print_center() {
  len=${#1}
  sep=$2
  buf=$((($COLUMNS-$len-2)/2))
  line=""
  for ((i=0; i < $buf; i++)) {
    line="$line$sep"
  }
  line="$line $1 "
  for ((i=0; i < $buf; i++)) {
    line="$line$sep"
  }
  echo ""
  echo $line
}

#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 2 argument:
#			string containing descriptive error message
#     string containing the root path of where the log will output
#	----------------------------------------------------------------
function __error_exit-deprecated
{
	echo "********************************************"
	echo "Failure to run quickstart script"
	echo "View logs at $2/quickstart.log"
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	echo "********************************************"
	echo -e $(timestamp): " --- ERROR:" "$1"  >> "$2/quickstartlog.log"
	echo -e $(timestamp): " --- Running the clean up script..." "$1"  >> "$2/quickstartlog.log"
	exit 1
}

#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 2 argument:
#			string containing descriptive error message
#     string containing the root path of where the log will output
#	-
function __error_exit ()
{
  echo "**************** Error Occurred ***************************"
	echo "Failure to run quickstart script"
	echo "View logs at $2/quickstartlog.log"
	#echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	echo "***********************************************************"
  echo -e $(timestamp): " --- ERROR:" "$1"  >> "$2/quickstartlog.log"
	echo -e $(timestamp): " --- Running the clean up script..." "$1"  >> "$2/quickstartlog.log"

  echo "**************** Stack Trace ****************************"
  local frame=0
  while caller $frame; do
    frame=$((frame+1))
  done
  echo ""
  echo "$*"

  echo "***********************************************************"

  echo "**************** Continue From ****************************"
  echo "You may continue from where you left off by providing a switch to continue from.  e.g. --continue-from -nodejs-starter"
  echo "Here are the switches that were being processed.  Please choose the one you are interested in continuing from.  You may pass in either the short version or the long version of the switch but not both."
  for ((i = 0; i < ${#SWITCH_DESC_ARRAY[@]}; i++))
  do
      switch="${SWITCH_DESC_ARRAY[$i]}"
      echo $switch
  done
  echo "***********************************************************"

  exit 1
}

#	----------------------------------------------------------------
#	Function for checking the expected number of arguments
#		Accepts 4 argument:
#			string containing the expected number
#			string of the actual number of arguments
#			string explaining the expected arguments
#     string containing the root path of where the log will output
#	----------------------------------------------------------------
function __validate_num_arguments
{
	if [[ "$#" -ne 4 ]] ; then

		ERRORMSG="__validate_num_arguments() - Expected (4), Actual($#) arguments. Expected in order: number of arguments, actual number of arguments, explaination of required arguments, path to where log will be generated"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$logDir/quickstartlog.log"
		exit 1
	fi

	if [[ "$1" -ne "$2" ]]; then
		ERRORMSG="Expected ($1), Actual($2) arguments. $3"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$4/quickstartlog.log"
		exit 1
	fi
}

# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    # perform cleanup here
    echo $(date +"%Y-%m-%d  %H:%M:%S") ": --- Ctrl-C caught...exiting script" >> "$logDir/quickstartlog.log"
    cf config --locale CLEAR
		exit 1
}
