#!/bin/bash
set -e
arguments="$*"

function __print_out_usage
{
	echo -e "Usage:\n"
	echo -e "./quickstart [ options ]\n"

  echo -e "options are as below"
  echo "[-b|       --branch]                        => Github Branch, default is master"

  echo -e "*** examples\n"
	echo -e "./quickstart-xxx.sh -uaa -asset -ts         => install services"
}

# Reset all variables that might be set
PRINT_USAGE=0
LOGIN=1
SKIP_INTERACTIVE=0
BRANCH="master"

function processReadargs() {
	#process all the switches as normal
	while :; do
			doShift=0
			processCloudBasicAppReadargsSwitch $@
			if [[ $doShift == 2 ]]; then
				shift
				shift
			fi
			if [[ $doShift == 1 ]]; then
				shift
			fi
			if [[ $@ == "" ]]; then
				break;
			else
	  			shift
			fi
			#echo "processReadargs $@"
	done

	printCommonVariables
}

function processCloudBasicAppReadargsSwitch() {
	#process all the switches as normal
	#echo "arg=$1"
  case $1 in
		-?*)
			doShift=0
			processSwitchCommon $@
			if [[ $UNKNOWN_SWITCH == 1 ]]; then
				if [[ $SUPPRESS_PRINT_UNKNOWN == 0 ]]; then
					echo "unknown BBA switch=$1"
				fi
			fi
			;;
		*)               # Default case: If no more options then break out of the loop.
			;;
  esac
}
