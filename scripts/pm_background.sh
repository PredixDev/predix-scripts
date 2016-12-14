PREDIX_MACHINE_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PREDIX_MACHINE_LOGS=$PREDIX_MACHINE_HOME/../../../logs/machine
mkdir -p $PREDIX_MACHINE_LOGS
touch $PREDIX_MACHINE_LOGS/machine.log
touch $PREDIX_MACHINE_LOGS/machine.err
nohup ./start_container.sh clean > $PREDIX_MACHINE_LOGS/machine.log 2> $PREDIX_MACHINE_LOGS/machine.err < /dev/null &
