# Predix Machine Config Setup Script (used within quickstart.sh)
# Authors: GE SDLP 2015-2016
# Expected inputs:
# issuerId_under_predix_uaa
# Timeseries_ingest_uri
# Timeseries_zone_id
# uri_under_predix_uaa
rootDir=$quickstartRootDir
source "$rootDir/bash/scripts/variables.sh"

ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}
PREDIX_MACHINE_HOME="$4"
cd "$PREDIX_MACHINE_HOME/configuration/machine/"
sed "s#com.ge.dspmicro.predixcloud.identity.uaa.token.url=.*#com.ge.dspmicro.predixcloud.identity.uaa.token.url=\"$1\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config

sed "s#com.ge.dspmicro.predixcloud.identity.uaa.clientid=.*#com.ge.dspmicro.predixcloud.identity.uaa.clientid=\"$UAA_CLIENTID_GENERIC\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config

sed "s#com.ge.dspmicro.predixcloud.identity.uaa.clientsecret=.*#com.ge.dspmicro.predixcloud.identity.uaa.clientsecret=\"$UAA_CLIENTID_GENERIC_SECRET\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config

if [[ $RUN_CREATE_TIMESERIES == 1 ]]; then
	sed "s#com.ge.dspmicro.websocketriver.send.destination.url=.*#com.ge.dspmicro.websocketriver.send.destination.url=\"$TIMESERIES_INGEST_URI\"#" com.ge.dspmicro.websocketriver.send-0.config > com.ge.dspmicro.websocketriver.send-0.config.tmp
	mv com.ge.dspmicro.websocketriver.send-0.config.tmp com.ge.dspmicro.websocketriver.send-0.config

	sed "s#com.ge.dspmicro.websocketriver.send.header.zone.value=.*#com.ge.dspmicro.websocketriver.send.header.zone.value=\"$TIMESERIES_ZONE_ID\"#" com.ge.dspmicro.websocketriver.send-0.config > com.ge.dspmicro.websocketriver.send-0.config.tmp
	mv com.ge.dspmicro.websocketriver.send-0.config.tmp com.ge.dspmicro.websocketriver.send-0.config

	WEBSOCKET_RIVER_NAME=$(grep "com.ge.dspmicro.websocketriver.send.river.name" com.ge.dspmicro.websocketriver.send-0.config | awk -F"=" '{print $2}' | tr -d '"')
	sed "s#com.ge.dspmicro.hoover.spillway.destination=.*#com.ge.dspmicro.hoover.spillway.destination=\"$WEBSOCKET_RIVER_NAME\"#" $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config > $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config.tmp
	mv $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config.tmp $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config
fi

if [[ $RUN_CREATE_EVENT_HUB == 1 ]]; then
	sed "s#com.ge.dspmicro.eventhubriver.send.publish.url=.*#com.ge.dspmicro.eventhubriver.send.destination.url=\"$EVENTHUB_INGEST_URI\"#" com.ge.dspmicro.eventhubriver.send-0.config > com.ge.dspmicro.eventhubriver.send-0.config.tmp
	mv com.ge.dspmicro.eventhubriver.send-0.config.tmp com.ge.dspmicro.eventhubriver.send-0.config

	sed "s#com.ge.dspmicro.eventhubriver.send.header.zone.value=.*#com.ge.dspmicro.eventhubriver.send.header.zone.value=\"$EVENTHUB_ZONE_ID\"#" com.ge.dspmicro.eventhubriver.send-0.config > com.ge.dspmicro.eventhubriver.send-0.config.tmp
	mv com.ge.dspmicro.eventhubriver.send-0.config.tmp com.ge.dspmicro.eventhubriver.send-0.config

	EVENTHUB_RIVER_NAME=$(grep "com.ge.dspmicro.eventhubriver.send.river.name" com.ge.dspmicro.eventhubriver.send-0.config | awk -F"=" '{print $2}' | tr -d '"')
	sed "s#com.ge.dspmicro.hoover.spillway.destination=.*#com.ge.dspmicro.hoover.spillway.destination=\"$EVENTHUB_RIVER_NAME\"#" $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config > $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config.tmp
	mv $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config.tmp $rootDir/../config/com.ge.dspmicro.hoover.spillway-0.config
fi

if [[ ! -z $ALL_PROXY ]]
then
	myProxyHostValue=${ALL_PROXY%:*}
	myProxyPortValue=${ALL_PROXY##*:}
	if [[ ! -z $myProxyHostValue ]]
	then
		myProxyEnabled="true"
	else
		myProxyEnabled="false"
	fi
else
	myProxyHostValue=""
	myProxyPortValue="8080"
	myProxyEnabled="false"
fi

sed "s#proxy.host=.*#proxy.host=\"$myProxyHostValue\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config

sed "s#proxy.port=I.*#proxy.port=I\"$myProxyPortValue\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config

sed "s#proxy.enabled=B.*#proxy.enabled=B\"$myProxyEnabled\"#" org.apache.http.proxyconfigurator-0.config > org.apache.http.proxyconfigurator-0.config.tmp
mv org.apache.http.proxyconfigurator-0.config.tmp org.apache.http.proxyconfigurator-0.config

cd $rootDir
