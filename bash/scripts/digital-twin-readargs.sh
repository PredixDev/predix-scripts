#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

source "$rootDir/bash/scripts/predix_services_setup.sh"
source "$rootDir/bash/scripts/build-basic-app-readargs.sh"

# Reset all variables that might be set
RUN_CREATE_ANALYTIC_FRAMEWORK=0
RUN_CREATE_RABBITMQ=0
USE_RMD_ANALYTICS=0
USE_RMD_ORCHESTRATION=0
BIND_RABBITMQ_DATAEXCHANGE=0

function processReadargs() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	while :; do
			#echo "processReadargs1 $@"
			doShift=0
			processDigitalTwinReadargsSwitch $@
			if [[ $doShift == 1 ]]; then
				shift
			fi
			if [[ $@ == "" ]]; then
				break;
			else
	  		shift
			fi
	done
	printDTVariables
}

function processDigitalTwinReadargsSwitch() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	#echo "digital-twin-readargs $1"
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
      -bindrmq|--bind-rabbitmq)
        BIND_RABBITMQ_DATAEXCHANGE=1
        SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-bindrmq | --bind-rabbitmq"
				SWITCH_ARRAY[SWITCH_INDEX++]="-bindrmq"
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
        ;;
      -?*)
				doShift=0
				SUPPRESS_PRINT_UNKNOWN=1
				UNKNOWN_SWITCH=0
				processBuildBasicAppReadargsSwitch $@
				if [[ $UNKNOWN_SWITCH == 1 ]]; then
					echo "unknown DT switch=$1"
				fi
        ;;
			*)               # Default case: If no more options then break out of the loop.
				;;
  esac
}

#echo "Switches=${SWITCH_DESC_ARRAY[*]}"
function printDTVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "0" ]]; then
		printBBAVariables
		echo "  DIGITAL TWIN:"
		echo "  SERVICES:"
		echo "    RUN_CREATE_ANALYTIC_FRAMEWORK            : $RUN_CREATE_ANALYTIC_FRAMEWORK"
		echo "    RUN_CREATE_RABBITMQ                      : $RUN_CREATE_RABBITMQ"
	  echo ""
	  echo "  BACK-END:"
		echo "    USE_RMD_ANALYTICS                        : $USE_RMD_ANALYTICS"
		echo "    USE_RMD_ORCHESTRATION                    : $USE_RMD_ORCHESTRATION"
	  echo ""
	fi

	export RUN_CREATE_ANALYTIC_FRAMEWORK
	export RUN_CREATE_RABBITMQ
}


function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Digital Twin options are as below"
  echo "services:"
	echo "[-rmq|      --create-rabbitmq]              => Create the rabbit mq service instance"
	echo "[-bindrmq|   --bind-rabbitmq]              => Bind rabbit mq with data exchange"
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
function runFunctionsForDigitalTwin() {
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
					-bindrmq|--bind-rabbitmq)
            bindRabbitMQInstance $DATAEXCHANGE_APP_NAME
	    setEnv $DATAEXCHANGE_APP_NAME $SPRING_PROFILES_ACTIVE $SPRING_PROFILES_ACTIVE_DT_REF_APP_VALUE
	    restageApp $DATAEXCHANGE_APP_NAME
	    getUrlForAppName $DATAEXCHANGE_APP_NAME APP_URL "https"
	    setEnv $FRONT_END_POLYMER_SEED_APP_NAME "dataExchangeURL" $APP_URL
	    restageApp $FRONT_END_POLYMER_SEED_APP_NAME
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
