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

#process all the switches as normal
while :; do
		#echo "arg=$1"
    case $1 in
        -h|-\?|--help)   # Call a "__print_out_usage" function to display a synopsis, then exit.
          __print_out_usage
          exit
          ;;
					-i|--instance-appender)       # Takes an option argument, ensuring it has been specified.
	          if [ -n "$2" ]; then
	              INSTANCE_PREPENDER=$(echo $2 | tr 'A-Z' 'a-z')
	              SWITCH_ARRAY[SWITCH_INDEX++]=value
	              shift
	          else
	              printf 'ERROR: "-i or --instance-appender" requires a non-empty option argument.\n' >&2
	              exit 1
	          fi
	          ;;
				-si|--skip-interactive)
		      SKIP_INTERACTIVE=1
		    ;;
				-script|--app-script)       # Takes an option argument, ensuring it has been specified.
          shift
          ;;
        -script-readargs)       # Takes an option argument, ensuring it has been specified.
          shift
          ;;
				-b|--branch)
					if [ -n "$2" ]; then
						BRANCH=$2
						shift
					else
						printf 'ERROR: "-b or --branch" requires a non-empty option argument.\n' >&2
						exit 1
					fi
					;;
        -?*)
          printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
          ;;
        *)               # Default case: If no more options then break out of the loop.
          break;
    esac
    shift
done
