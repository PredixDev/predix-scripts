#!/bin/bash
set -e

ERROR_HANDLING_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ERROR_HANDLING_LogDir="$ERROR_HANDLING_PATH/../log"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will all for error handling
#

# ********************************** HELPER FUNCTIONS **********************************
#
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
function __error_exit
{
	echo "********************************************"
	echo "Failure to run quickstart script"
	echo "View logs at $2/quickstartlog.log"
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	echo "********************************************"
	echo -e $(timestamp): " --- ERROR:" "$1"  >> "$2/quickstartlog.log"
	echo -e $(timestamp): " --- Running the clean up script..." "$1"  >> "$2/quickstartlog.log"
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
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$ERROR_HANDLING_LogDir/quickstartlog.log"
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
    echo $(date +"%Y-%m-%d  %H:%M:%S") ": --- Ctrl-C caught...exiting script" >> "$ERROR_HANDLING_LogDir/quickstartlog.log"
    cf config --locale CLEAR
		exit 1
}

function __print_out_usage
{
	echo -e "Usage:\n"
	echo -e "./quickstart [ options ]\n"

  echo -e "options are as below"
  echo "[-h|--help]                           => Print usage"
  echo "[-q|--quiet-mode]                     => Quiet mode"
  echo "[-i|--instance-prepender]            => Instance appender to identify your service and application instances"
  echo "[-tu|--training-uaa]                  => Use a Training UAA Instance. Default does not use the Training UAA instance"
  echo "[-ds|--delete-services]               => Delete the service instances previously created"
  echo "[-cs|--create-services]               => Create the service instances"
  echo "[-mc|--machine-config]                => Configure machine container with valid endpoints to UAA and Time Series"
  echo "[-cc|--clean-compile]                 => Force clean and compile the Device specific repo"
  echo "[-mt|--machine-transfer]              => Transfer the configured Machine container to desired device"
  echo "[-if|--install-frontend]              => Install the front-end app to visualize the data"
  echo "[-fb|--frontendapp-branch]            => Github Branch of the front-end nodejs app, default is master"
  echo "[-wd|--wind-data]                     => User winddata-timeseries-service as backend (y/n)"
  echo "[-s|--maven-settings]                 => location of mvn settings.xml file, default is ~/.m2/settings.xml"
  echo "[-p|--print-vcaps]                    => Print the VCAPS info"
  echo "[-all]                                => Do everything -> Create services, install front-end, configure machine, compile repo, transfer machine"



	echo -e "*** examples\n"
	echo -e "./quickstart.sh -cs                => only services installed and deployed"
	echo -e "./quickstart.sh -cs -if            => only services and front-end app deployed"
	echo -e "./quickstart.sh -cs -mc            => only services deployed and predix machine configured"
	echo -e "./quickstart.sh -cs -mc -cc -mt    => create services, machine config, compile repo and transfer machine container"
  echo -e "./quickstart.sh -all               => create services, install front-end, configure machine, compile repo, transfer machine"
}
