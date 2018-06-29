#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

#source "$rootDir/bash/scripts/predix_services_setup.sh"


# Reset all variables that might be set
RUN_EDGE_STARTER=0

source "$rootDir/bash/scripts/build-basic-app-readargs.sh"


function processReadargs() {
	#process all the switches as normal
	while :; do
			doShift=0
			processEdgeStarterReadargsSwitch $@
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
	#echo "Switches=${SWITCH_DESC_ARRAY[*]}"

	printEdgeStarterVariables
}

function processEdgeStarterReadargsSwitch() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	#echo "here$@"
	case $1 in
		-es|--edge-starter)
				RUN_EDGE_STARTER=1
				SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-es | --edge-starter"
				SWITCH_ARRAY[SWITCH_INDEX++]="-es"
				PRINT_USAGE=0
				LOGIN=1
				;;
			-?*)
				doShift=0
				SUPPRESS_PRINT_UNKNOWN=1
				UNKNOWN_SWITCH=0
				processBuildBasicAppReadargsSwitch $@
				if [[ $UNKNOWN_SWITCH == 1 ]]; then
					echo "unknown Edge Starter switch=$1"
				fi
        ;;
			*)               # Default case: If no more options then break out of the loop.
				;;
  esac
}


function printEdgeStarterVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
		printBBAVariables
		echo "EDGE STARTER:"
		echo "    RUN_EDGE_STARTER                         : $RUN_EDGE_STARTER"

	  echo ""
	fi

	export RUN_EDGE_STARTER

}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-es |      --edge-starter]          => Setup hello world for edge starter"

}

#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionsForEdgeStarter() {
	while :; do
			SUPPRESS_PRINT_UNKNOWN=1
			runFunctionsForBasicApp $1 $2
	    case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-es|--edge-starter)
							if [[ $RUN_EDGE_STARTER -eq 1 ]]; then
								source "$rootDir/bash/scripts/edge-starter-hello-world.sh"
								edge-starter-hello-world-main $1
							fi
							break
							;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
}
