#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"

# Reset all variables that might be set
RUN_CREATE_ANALYTIC_FRAMEWORK=0
RUN_CREATE_RABBITMQ=0
USE_RMD_ANALYTICS=0
USE_RMD_ORCHESTRATION=0

#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
while :; do
		#echo "here$@"
		case $1 in
        -af|--create-analytic-framework)
          RUN_CREATE_ANALYTIC_FRAMEWORK=1
          SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-af | --create-analytic-framework"
					SWITCH_ARRAY[SWITCH_INDEX++]="-af"
          PRINT_USAGE=0
          LOGIN=1
          ;;
        -rmq|--create-rabbitmq)
          RUN_CREATE_RABBITMQ=1
          SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-rmq | --create-rabbitmq"
					SWITCH_ARRAY[SWITCH_INDEX++]="-rmq"
          PRINT_USAGE=0
          LOGIN=1
          ;;
				-armd|--rmd-analytics)       # Takes an option argument, ensuring it has been specified.
            USE_RMD_ANALYTICS=1
            SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-armd | --rmd-analytics"
						SWITCH_ARRAY[SWITCH_INDEX++]="-armd"
            PRINT_USAGE=0
            VERIFY_MVN=1
            LOGIN=1
          ;;
        -fce|--rmd-orchestration)       # Takes an option argument, ensuring it has been specified.
            USE_RMD_ORCHESTRATION=1
            SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-fce | --rmd-orchestration"
						SWITCH_ARRAY[SWITCH_INDEX++]="-fce"
            PRINT_USAGE=0
            VERIFY_MVN=1
            LOGIN=1
          ;;
        --)
				  # End of all options.
					shift
					break
          ;;
        -?*)
					doShift=0
					processSwitchCommon $@
					if [[ $doShift == 1 ]]; then
						shift
					fi
          ;;
				*)               # Default case: If no more options then break out of the loop.
					echo "default" # End of all options.
          break
					;;
    esac
  	shift
done

#echo "Switches=${SWITCH_DESC_ARRAY[*]}"

if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
	printCommonVariables
  echo "SERVICES:"
	echo "RUN_CREATE_ANALYTIC_FRAMEWORK            : $RUN_CREATE_ANALYTIC_FRAMEWORK"
	echo "RUN_CREATE_RABBITMQ                      : $RUN_CREATE_RABBITMQ"
  echo ""
  echo "BACK-END:"
	echo "USE_RMD_ANALYTICS                        : $USE_RMD_ANALYTICS"
	echo "USE_RMD_ORCHESTRATION                    : $USE_RMD_ORCHESTRATION"
  echo ""
fi

exportCommonVariables
export RUN_CREATE_ANALYTIC_FRAMEWORK
export RUN_CREATE_RABBITMQ

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Digital Twin options are as below"
  echo "services:"
	echo "[-rmq|      --create-rabbitmq]              => Create the rabbit mq service instance"
	echo "[-af|      --create-analytic-framework]     => Create the analytic framework service instance"
  echo "back-end:"
	echo "[-armd|    --rmd-analytics]                 => Use rmd-analytics as backend"
  echo "[-fce|     --rmd-orchestration]             => Use rmd-orchestration as backend"

	echo -e "*** examples\n"
	echo -e "./$SCRIPT_NAME -rmq                      => install rabbit mq service"
}

#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionForDigitalTwin() {
	while :; do
			runFunctionForCommon $1 $2
	    case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					-rmq|--create-rabbitmq)
            createRabbitMQInstance $1
            break
            ;;
					-af|--create-analytic-framework)
            createAnalyticFrameworkServiceInstance $1
            break
            ;;
	        -fce|--rmd-orchestration)       # Takes an option argument, ensuring it has been specified.
						if [[ $USE_RMD_ORCHESTRATION -eq 1 ]]; then
					    source "$rootDir/bash/scripts/digital-twin-rmdorchestration.sh"
					    digital-twin-rmdorchestration-main $1
					  fi
	          break
						;;
	        -armd|--rmd-analytics)       # Takes an option argument, ensuring it has been specified.
						if [[ $USE_RMD_ANALYTICS -eq 1 ]]; then
					    source "$rootDir/bash/scripts/digital-twin-rmdanalytics.sh"
					    digital-twin-rmdanalytics-main $1
					  fi
	          break
						;;
	        *)
            echo 'WARN: Unknown function (ignored) in runFunction: %s\n' "$2" >&2
            break
						;;
	    esac
	done
}
