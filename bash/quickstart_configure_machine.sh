#!/bin/bash
set -e
quickstartRootDir="$( pwd )"
UPGRAGE_MACHINE_VERSION="17.1.3"
PREDIX_MACHINE_URL="https://raw.githubusercontent.com/PredixDev/predix-machine-templates/master/PredixMachine17.1.3.tar"
PREDIXMACHINE_TAR_FILENAME="$(echo $PREDIX_MACHINE_URL |awk -F"/" '{print $NF}')"
export quickstartRootDir

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

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Be sure to set all your variables in the variables.sh file before you run quick start!

function local_read_args() {
  while (( "$#" )); do
    opt="$1"
    case $opt in
        -h|-\?|--\?--help)
        echo -e "**************** Usage ***************************"
        echo -e "     ./$0 [ options ]\n"
        echo -e "     options are as below"
	      echo "        [-get-machine-config]           => Get Machine Configuration"
				echo "        [-upgrade-machine]              => Upgrade Machine to $UPGRAGE_MACHINE_VERSION"
        echo "        [-predix-machine-home]          => Predix Machine Installation directory"
        echo "        [-timeseries-ingest-url]        => Timeseries Websocket Endpoint URL for Data Ingestion"
        echo "        [-timeseries-zone-id]           => Time Series Zone Id"
				echo "        [-kitservice-url]               => Predix Kit Service URL"
        echo "        [-uaa-url]                      => UAA Url"
        echo "        [-uaa-clientid-secret]          => base64 encoded client_id:secret"
				echo "        [-databus-topics]               => Topics for Databus Adapter. Comma separated list if using more than one topic"
        echo "        [-proxy-host]                   => Proxy hostname if applicable"
        echo "        [-proxy-port]                   => Proxy port if applicable"
        echo "        [-h|-?|--?|   --help]           => Print usage"
        exit
        ;;
			-upgrade-machine)
				UPGRAGE_MACHINE=1
				;;
      -predix-machine-home)
        PREDIX_MACHINE_HOME="$2"
        if [ "$PREDIX_MACHINE_HOME" == "" ]; then
            printf 'ERROR: "-predix-machine-home" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
			-get-machine-config)
				GET_MACHINE_CONFIG="1"
				;;
      -proxy-host)
        PROXY_HOST=$2
        ;;
      -proxy-port)
        PROXY_PORT=$2
        ;;
      -timeseries-ingest-url)
        TIMESERIES_INGEST_URI="$2"
        if [ "$TIMESERIES_INGEST_URI" == "" ]; then
            printf 'ERROR: "-timeseries-ingest-url" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
      -timeseries-zone-id)
        if [ -n "$2" ]; then
          TIMESERIES_ZONE_ID="$2"
        else
            printf 'ERROR: "-timeseries-zone-id" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
      -uaa-url)
        TRUSTED_ISSUER_ID="$2"
        if [ "$TRUSTED_ISSUER_ID" == "" ]; then
            printf 'ERROR: "-uaa-url" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
      -uaa-clientid-secret)
        if [ -n "$2" ]; then
					if [ "$(uname -s)" == "Darwin" ];then
	          UAA_CLIENTID_GENERIC=$(echo $2 | base64 -D | awk -F":" '{print $1}')
	          UAA_CLIENTID_GENERIC_SECRET=$(echo $2 | base64 -D | awk -F":" '{print $2}')
					else
						UAA_CLIENTID_GENERIC=$(echo $2 | base64 -d | awk -F":" '{print $1}')
	          UAA_CLIENTID_GENERIC_SECRET=$(echo $2 | base64 -d | awk -F":" '{print $2}')
					fi
          export UAA_CLIENTID_GENERIC
          export UAA_CLIENTID_GENERIC_SECRET
        else
            printf 'ERROR: "-uaa-clientid-secret" requires a non-empty option argument.\n' >&2
            exit 1
        fi
        ;;
				-kitservice-url)
					PREDIX_KIT_URL="$2"
					if [ "$PREDIX_KIT_URL" == "" ]; then
            printf 'ERROR: "-kitservice-url" requires a non-empty option argument.\n' >&2
            exit 1
					fi
				;;
			-databus-topics)
        DATABUS_TOPICS="$2"
        if [ "$DATABUS_TOPICS" == "" ]; then
            printf 'ERROR: "-databus-topics" requires a non-empty option argument. If more than one, then comma separated topics\n' >&2
            exit 1
        fi
        ;;
      *)
        QUICKSTART_ARGS+=" $1"
        #echo $1
        ;;
    esac
    shift
  done
}
PARAMS="$@"
if [[ "$PARAMS" == "" ]]; then
  PARAMS="-h"
fi

PROXY_PORT="8080"
PROXY_HOST=""
PREDIX_MACHINE_HOME=""
TIMESERIES_ZONE_ID=""
TIMESERIES_INGEST_URI=""
UAA_CLIENTID_GENERIC=""
UAA_CLIENTID_GENERIC_SECRET=""

local_read_args $PARAMS


#echo "TRUSTED_ISSUER_ID           : $TRUSTED_ISSUER_ID"
#echo "TIMESERIES_INGEST_URI       : $TIMESERIES_INGEST_URI"
#echo "TIMESERIES_ZONE_ID          : $TIMESERIES_ZONE_ID"
#echo "PREDIX_MACHINE_HOME         : $PREDIX_MACHINE_HOME"
#echo "UAA_CLIENTID_GENERIC        : $UAA_CLIENTID_GENERIC"
#echo "UAA_CLIENTID_GENERIC_SECRET : $UAA_CLIENTID_GENERIC_SECRET"
#echo "DATABUS_TOPICS							: $DATABUS_TOPICS"
if [[ "$PREDIX_MACHINE_HOME" == "" ]]; then
	local_read_args "-h"
fi
if [[ ! -d $PREDIX_MACHINE_HOME ]]; then
  echo "$PREDIX_MACHINE_HOME does not exist. Please make sure Predix Machine is installed on the device and try again."
  exit 1
fi
if [[ "$UPGRAGE_MACHINE" == "1" ]]; then
	curl -O $PREDIX_MACHINE_URL
	mv $PREDIX_MACHINE_HOME "$PREDIX_MACHINE_HOME-17.1.2"
	mkdir -p $PREDIX_MACHINE_HOME
	tar xvf $PREDIXMACHINE_TAR_FILENAME -C $PREDIX_MACHINE_HOME
	cp $PREDIX_MACHINE_HOME-17.1.2/machine/bin/setvars.sh $PREDIX_MACHINE_HOME/machine/bin/setvars.sh
	chmod -R 777 $PREDIX_MACHINE_HOME
	chown -R gwuser $PREDIX_MACHINE_HOME
fi
if [[ "$HTTPS_PROXY" != "" ]]; then
	PROXY_HOST=$(echo $HTTPS_PROXY | awk -F"//" '{print $2}' | awk -F":" '{print $1}')
	PROXY_PORT=$(echo $HTTPS_PROXY | awk -F"//" '{print $2}' | awk -F":" '{print $2}')
elif [[ "$HTTP_PROXY" != "" ]]; then
	PROXY_HOST=$(echo $HTTP_PROXY | awk -F"//" '{print $2}' | awk -F":" '{print $1}')
	PROXY_PORT=$(echo $HTTP_PROXY | awk -F"//" '{print $2}' | awk -F":" '{print $2}')
elif [[ "$https_proxy" != "" ]]; then
	PROXY_HOST=$(echo $https_proxy | awk -F"//" '{print $2}' | awk -F":" '{print $1}')
	PROXY_PORT=$(echo $https_proxy | awk -F"//" '{print $2}' | awk -F":" '{print $2}')
elif [[ "$http_proxy" != "" ]]; then
	PROXY_HOST=$(echo $http_proxy | awk -F"//" '{print $2}' | awk -F":" '{print $1}')
	PROXY_PORT=$(echo $http_proxy | awk -F"//" '{print $2}' | awk -F":" '{print $2}')
fi
cd "$PREDIX_MACHINE_HOME/configuration/machine/"
if [[ "$GET_MACHINE_CONFIG" == "1" ]]; then
	TIMESERIES_INGEST_URI=$(grep "com.ge.dspmicro.websocketriver.send.destination.url" com.ge.dspmicro.websocketriver.send-0.config | awk -F"=" '{print $2}' | tr -d '"')
	TIMESERIES_ZONE_ID=$(grep "com.ge.dspmicro.websocketriver.send.header.zone.value" com.ge.dspmicro.websocketriver.send-0.config | awk -F"=" '{print $2}' | tr -d '"')
	TRUSTED_ISSUER_ID=$(grep "com.ge.dspmicro.predixcloud.identity.uaa.token.url" com.ge.dspmicro.predixcloud.identity.config | awk -F"=" '{print $2}' | tr -d '"')
	UAA_CLIENTID_GENERIC=$(grep "com.ge.dspmicro.predixcloud.identity.uaa.clientid" com.ge.dspmicro.predixcloud.identity.config | awk -F"=" '{print $2}' | tr -d '"')
	KEYS="timeseries-ingest-url|timeseries-zone-id|uaa-url|uaa-clientid
$TIMESERIES_INGEST_URI|$TIMESERIES_ZONE_ID|$TRUSTED_ISSUER_ID|$UAA_CLIENTID_GENERIC"
	#jq -Rn ' ( input  | split("|") ) as $keys | ( inputs | split("|") ) as $vals | [[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries' <<< "$KEYS" | sed 's/\\r//g'
	printf '{"timeseries-ingest-url":"%q","timeseries-zone-id":"%q","uaa-url":"%q","uaa-clientid":"%q"}\n' "$TIMESERIES_INGEST_URI" "$TIMESERIES_ZONE_ID" "$TRUSTED_ISSUER_ID" "$UAA_CLIENTID_GENERIC" | tr -d "\$'" | sed -e 's/\\r//g'
else
	if [[ "$TIMESERIES_INGEST_URI" != "" ]]; then
		echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
		sed "s#com.ge.dspmicro.websocketriver.send.destination.url=.*#com.ge.dspmicro.websocketriver.send.destination.url=\"$TIMESERIES_INGEST_URI\"#" com.ge.dspmicro.websocketriver.send-0.config > com.ge.dspmicro.websocketriver.send-0.config.tmp
		mv com.ge.dspmicro.websocketriver.send-0.config.tmp com.ge.dspmicro.websocketriver.send-0.config
		echo "Updated Timeseries Ingestion URL successfully"
	fi
	if [[ "$TIMESERIES_ZONE_ID" != "" ]]; then
		echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
		sed "s#com.ge.dspmicro.websocketriver.send.header.zone.value=.*#com.ge.dspmicro.websocketriver.send.header.zone.value=\"$TIMESERIES_ZONE_ID\"#" com.ge.dspmicro.websocketriver.send-0.config > com.ge.dspmicro.websocketriver.send-0.config.tmp
		mv com.ge.dspmicro.websocketriver.send-0.config.tmp com.ge.dspmicro.websocketriver.send-0.config
		echo "Updated Timeseries Zone Id successfully"
	fi

	if [[ "$TRUSTED_ISSUER_ID" != "" ]]; then
		sed "s#com.ge.dspmicro.predixcloud.identity.uaa.token.url=.*#com.ge.dspmicro.predixcloud.identity.uaa.token.url=\"$TRUSTED_ISSUER_ID\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
		mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config
		echo "Updated UAA Token URL successfully"
	fi

	if [[ "$UAA_CLIENTID_GENERIC" != "" ]]; then
		sed "s#com.ge.dspmicro.predixcloud.identity.uaa.clientid=.*#com.ge.dspmicro.predixcloud.identity.uaa.clientid=\"$UAA_CLIENTID_GENERIC\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
		mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config
		echo "Updated UAA Client Id successfully"
	fi

	if [[ "$UAA_CLIENTID_GENERIC_SECRET" != "" ]]; then
		sed "s#com.ge.dspmicro.predixcloud.identity.uaa.clientsecret=.*#com.ge.dspmicro.predixcloud.identity.uaa.clientsecret=\"$UAA_CLIENTID_GENERIC_SECRET\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
		mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config
		echo "Updated UAA Client Secret successfully"
	fi

	if [[ "$PREDIX_KIT_URL" != "" ]]; then
		sed "s#com.ge.predix.solsvc.edgestarter.predixkit.device.get.url=.*#com.ge.predix.solsvc.edgestarter.predixkit.device.get.url=\"$PREDIX_KIT_URL\"#" com.ge.predix.solsvc.edgestarter.processor.config.config > com.ge.predix.solsvc.edgestarter.processor.config.config.tmp
		mv com.ge.predix.solsvc.edgestarter.processor.config.config.tmp com.ge.predix.solsvc.edgestarter.processor.config.config
		echo "Updated Predix Kit Service URL successfully"
	fi

	if [[ "$PROXY_HOST" != "" ]]; then
		myProxyEnabled="true"
		sed "s#proxy.host=.*#proxy.host=\"$PROXY_HOST\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
		mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config
	else
		myProxyEnabled="false"
	fi

	sed "s#proxy.port=I.*#proxy.port=I\"$PROXY_PORT\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
	mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config

	sed "s#proxy.enabled=B.*#proxy.enabled=B\"$myProxyEnabled\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
	mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config

#	if [[ ! -z $DATABUS_TOPICS ]]; then
#		TOPIC_ARRAY="["
#		for topic in $(echo $DATABUS_TOPICS | awk -F"," '{for (i=1;i<=NF;i++)print $i}'); do
#			TOPIC_ARRAY="$TOPIC_ARRAY \"$topic\",\\"
#		done
#		TOPIC_ARRAY="$TOPIC_ARRAY ]"
#		echo "TOPIC_ARRAY : $TOPIC_ARRAY"
#		sed "s#com.ge.dspmicro.machineadapter.databus.subscriptions=.*#com.ge.dspmicro.machineadapter.databus.subscriptions=$TOPIC_ARRAY#" com.ge.dspmicro.machineadapter.databus-0.config > com.ge.dspmicro.machineadapter.databus-0.config.tmp
#		mv com.ge.dspmicro.machineadapter.databus-0.config.tmp com.ge.dspmicro.machineadapter.databus-0.config

#		sed "s#com.ge.dspmicro.hoover.spillway.destination=.*#com.ge.dspmicro.hoover.spillway.destination=\"WS Sender Service\"#" com.ge.dspmicro.hoover.spillway-0.config > com.ge.dspmicro.hoover.spillway-0.config.tmp
#		mv com.ge.dspmicro.hoover.spillway-0.config.tmp com.ge.dspmicro.hoover.spillway-0.config

#		sed "s#com.ge.dspmicro.hoover.spillway.processType=.*#com.ge.dspmicro.hoover.spillway.processType=\"Workshop\"#" com.ge.dspmicro.hoover.spillway-0.config > com.ge.dspmicro.hoover.spillway-0.config.tmp
#		mv com.ge.dspmicro.hoover.spillway-0.config.tmp com.ge.dspmicro.hoover.spillway-0.config

#		count=$(grep "PredixKitTopic" com.ge.dspmicro.hoover.spillway-0.config | wc -l)
#		echo "Count $count"
#		if [[ $count -gt 0 ]]; then
#			sed -e '/dataSubscriptions/ {n;N;N;N;N;d;}' com.ge.dspmicro.hoover.spillway-0.config > com.ge.dspmicro.hoover.spillway-0.config.tmp
#			mv com.ge.dspmicro.hoover.spillway-0.config.tmp com.ge.dspmicro.hoover.spillway-0.config
#		fi

#		sed "s#com.ge.dspmicro.hoover.spillway.dataSubscriptions=.*#com.ge.dspmicro.hoover.spillway.dataSubscriptions=$TOPIC_ARRAY#" com.ge.dspmicro.hoover.spillway-0.config > com.ge.dspmicro.hoover.spillway-0.config.tmp
#		mv com.ge.dspmicro.hoover.spillway-0.config.tmp com.ge.dspmicro.hoover.spillway-0.config
#	fi
	sed "s#com.ge.dspmicro.storeforward.databasePassword.encrypted=.*#com.ge.dspmicro.storeforward.databasePassword.encrypted=\"\"#" com.ge.dspmicro.storeforward-0.config > com.ge.dspmicro.storeforward-0.config.tmp
	mv com.ge.dspmicro.storeforward-0.config.tmp com.ge.dspmicro.storeforward-0.config

	sed "s#com.ge.dspmicro.storeforward.encryptionPassword.encrypted=.*#com.ge.dspmicro.storeforward.encryptionPassword.encrypted=\"\"#" com.ge.dspmicro.storeforward-0.config > com.ge.dspmicro.storeforward-0.config.tmp
	mv com.ge.dspmicro.storeforward-0.config.tmp com.ge.dspmicro.storeforward-0.config

	sed "s#com.ge.dspmicro.storeforward.databasePassword.encrypted=.*#com.ge.dspmicro.storeforward.databasePassword.encrypted=\"\"#" com.ge.dspmicro.storeforward-taskstatus.config > com.ge.dspmicro.storeforward-taskstatus.config.tmp
	mv com.ge.dspmicro.storeforward-taskstatus.config.tmp com.ge.dspmicro.storeforward-taskstatus.config

	sed "s#com.ge.dspmicro.storeforward.encryptionPassword.encrypted=.*#com.ge.dspmicro.storeforward.encryptionPassword.encrypted=\"\"#" com.ge.dspmicro.storeforward-taskstatus.config > com.ge.dspmicro.storeforward-taskstatus.config.tmp
	mv com.ge.dspmicro.storeforward-taskstatus.config.tmp com.ge.dspmicro.storeforward-taskstatus.config

	echo "Predix Machine configuration updated successfully"
fi
