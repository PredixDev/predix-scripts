# Predix Cloud Foundry Credentials
# Keep all values inside double quotes

#########################################################
# Mandatory User configurations that need to be updated
#########################################################

############## Proxy Configurations #############

# Proxy settings in format proxy_host:proxy_port
# Leave as is if no proxy
ALL_PROXY=":8080"

############## Configurations #############
# Name for your Back End Application
DATAEXCHANGE_APP_NAME="$INSTANCE_PREPENDER-data-exchange"
DATA_SIMULATOR_APP_NAME="$INSTANCE_PREPENDER-data-exchange-simulator"
WEBSOCKET_SERVER_APP_NAME="$INSTANCE_PREPENDER-data-exchange"
WINDDATA_SERVICE_APP_NAME="$INSTANCE_PREPENDER-winddata-service"
RMD_DATASOURCE_APP_NAME="$INSTANCE_PREPENDER-rmd-datasource"
RMD_ORCHESTRATION_APP_NAME="$INSTANCE_PREPENDER-rmd-orchestration"
RMD_ANALYTICS_APP_NAME="$INSTANCE_PREPENDER-rmd-analytics"
KIT_SERVICE_APP_NAME="$INSTANCE_PREPENDER-kit-service"
# Name for your Front End Application
FRONT_END_NODEJS_STARTER_APP_NAME="$INSTANCE_PREPENDER-nodejs-starter"
FRONT_END_POLYMER_SEED_APP_NAME="$INSTANCE_PREPENDER-predix-webapp-starter"
FRONT_END_POLYMER_SEED_UAA_APP_NAME="$INSTANCE_PREPENDER-predix-webapp-starter"
FRONT_END_POLYMER_SEED_ASSET_APP_NAME="$INSTANCE_PREPENDER-predix-webapp-starter"
FRONT_END_POLYMER_SEED_TIMESERIES_APP_NAME="$INSTANCE_PREPENDER-predix-webapp-starter"
FRONT_END_POLYMER_SEED_RMD_APP_NAME="$INSTANCE_PREPENDER-predix-webapp-starter"
FRONT_END_DATAEXCHANGE_UI_APP_NAME="$INSTANCE_PREPENDER-data-exchange-ui"
FRONT_END_KIT_APP_NAME="$INSTANCE_PREPENDER-kit-app"
# Name for your Mobile Application
MOBILE_STARTER_APP_NAME="$INSTANCE_PREPENDER-predix-mobile-starter"
SPRING_PROFILES_ACTIVE="SPRING_PROFILES_ACTIVE"
SPRING_PROFILES_ACTIVE_VALUE="cloud,asset,timeseries,dxwebsocket,rabbitmq"

############### UAA Configurations ###############

# The username of the new user to authenticate with the application
UAA_USER_NAME="app_user_1"

# The email address of username above
UAA_USER_EMAIL="app_user_1@ge.com"

# The password of the user above
UAA_USER_PASSWORD="App_User_111"

# The secret of the Admin client ID (Administrator Credentails)
if [[ $UAA_ADMIN_SECRET == "" ]]; then
	UAA_ADMIN_SECRET="secret"
fi

# The generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_LOGIN="login_client_id"

# The generic client ID password
if [[ $UAA_CLIENTID_LOGIN_SECRET == "" ]]; then
	UAA_CLIENTID_LOGIN_SECRET="secret"
fi

# The generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_GENERIC="app_client_id"

# The generic client ID password
if [[ $UAA_CLIENTID_GENERIC_SECRET == "" ]]; then
	UAA_CLIENTID_GENERIC_SECRET="secret"
fi

# The machine generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_DEVICE="device_client_id"

# The machine generic client ID password
if [[ $UAA_CLIENTID_DEVICE_SECRET == "" ]]; then
	UAA_CLIENTID_DEVICE_SECRET="secret"
fi

############# Predix ANALYTIC FRAMEWORK SERVICE'S Analytic User Interface(UI)'s login credential Configurations#############

ANALYTIC_UI_USER_NAME="app_user_1"
ANALYTIC_UI_PASSWORD="App_User_111"
ANALYTIC_UI_USER_EMAIL="app_user_1@ge.com"


############# Predix Kits Admin User#############

KIT_ADMIN_USER_NAME="kit_admin_1"
KIT_ADMIN_PASSWORD="Kit_Admin_111"
KIT_ADMIN_USER_EMAIL="kit_admin_1@ge.com"

# Group for Predix Admin
KIT_ADMIN_GROUP="predixkit.admin"

############# Predix Asset Configurations #############

# Name of the "Asset" that is recorded to Predix Asset
ASSET_TYPE="asset"

# Name of the tag (Asset name ex: Wind Turbine) you want to ingest to timeseries with. NO SPACES
# To create multiple tags separate each tag with a single comma (,)
ASSET_TAG="device1"

#Description of the Machine that is recorded to Predix Asset
ASSET_DESCRIPTION="device1"

###############################
# Optional configurations
###############################

# Name for the temp_app application
TEMP_APP="$INSTANCE_PREPENDER-hello-world"
TEMP_APP_GIT_HUB_URL="https://github.com/PredixDev/Predix-HelloWorld-WebApp.git"
TEMP_APP_GIT_HUB_VERSION="1.0.0"
############### UAA Configurations ###############

if [[ $USE_TRAINING_UAA -eq 1 ]]; then
	export UAA_SERVICE_NAME="predix-uaa-training"
	export UAA_PLAN="Free"
else
  # The name of the UAA service you are binding to - default already set
  UAA_SERVICE_NAME="predix-uaa"
  # Name of the UAA plan (eg: Free) - default already set
  UAA_PLAN="Free"
fi

# Name of your UAA instance - default already set
if [[ -n "$CUSTOM_UAA_INSTANCE" ]]; then
	UAA_INSTANCE_NAME="$CUSTOM_UAA_INSTANCE"
else
	UAA_INSTANCE_NAME="$INSTANCE_PREPENDER-uaa"
fi



############# Predix TimeSeries Configurations ##############

#The name of the TimeSeries service you are binding to - default already set
TIMESERIES_SERVICE_NAME="predix-timeseries"

#Name of the TimeSeries plan (eg: Free) - default already set
TIMESERIES_SERVICE_PLAN="Free"


#Name of your TimeSeries instance - default already set
if [[ -n "$CUSTOM_TIMESERIES_INSTANCE" ]]; then
	TIMESERIES_INSTANCE_NAME="$CUSTOM_TIMESERIES_INSTANCE"
else
	TIMESERIES_INSTANCE_NAME="$INSTANCE_PREPENDER-time-series"
fi


############# Predix Access Control Service Configurations ##############

#The name of the Asset service you are binding to - default already set
ACCESS_CONTROL_SERVICE_NAME="predix-acs"

#Name of the Asset plan (eg: Free) - default already set
ACCESS_CONTROL_SERVICE_PLAN="Free"

#Name of your Asset instance - default already set
ACCESS_CONTROL_SERVICE_INSTANCE_NAME="$INSTANCE_PREPENDER-acs"

############# Predix Asset Configurations ##############

#The name of the Asset service you are binding to - default already set
ASSET_SERVICE_NAME="predix-asset"

#The name of the Eventhub service you are binding to - default already set
EVENTHUB_SERVICE_NAME="predix-event-hub"

#The name of the blobstore service you are binding to - default already set
BLOBSTORE_SERVICE_NAME="predix-blobstore"

#Name of the Asset plan (eg: Free) - default already set
ASSET_SERVICE_PLAN="Free"

#Name of the EventHub plan (eg: Free) - default already set
EVENTHUB_SERVICE_PLAN="Tiered"

#Name of the Blobstore plan (eg: Free) - default already set
BLOBSTORE_SERVICE_PLAN="Tiered"

#Name of your Asset instance - default already set
if [[ -n "$CUSTOM_ASSET_INSTANCE" ]]; then
	ASSET_INSTANCE_NAME="$CUSTOM_ASSET_INSTANCE"
else
	ASSET_INSTANCE_NAME="$INSTANCE_PREPENDER-asset"
fi

#Name of your eventhub instance - default already set
if [[ -n "$CUSTOM_EVENTHUB_INSTANCE" ]]; then
	EVENTHUB_INSTANCE_NAME="$CUSTOM_EVENTHUB_INSTANCE"
else
	EVENTHUB_INSTANCE_NAME="$INSTANCE_PREPENDER-eventhub"
fi
#Name of your eventhub instance - default already set
if [[ -n "$CUSTOM_BLOBSTORE_INSTANCE" ]]; then
	BLOBSTORE_INSTANCE_NAME="$CUSTOM_BLOBSTORE_INSTANCE"
else
	BLOBSTORE_INSTANCE_NAME="$INSTANCE_PREPENDER-blobstore"
fi
############# Predix Mobile Configurations ##############

#The name of the Mobile service you are binding to - default already set
MOBILE_SERVICE_NAME="predix-mobile"

#Name of the Asset plan (eg: Free) - default already set
MOBILE_SERVICE_PLAN="Free"

#Name of your Mobile instance - default already set
MOBILE_INSTANCE_NAME="$INSTANCE_PREPENDER-mobile"

# MOBILE UAA Client/secret for API GATEWAY OAUTH
MOBILE_OAUTH_API_CLIENT="pm-api-gateway-oauth"
MOBILE_OAUTH_API_CLIENT_SECRET="Pr3dixMob1le"

RABBITMQ_SERVICE_INSTANCE_NAME="$INSTANCE_PREPENDER-rmq"
RABBITMQ_SERVICE_PLAN="Dedicated-1-Q40"
RABBITMQ_SERVICE_NAME="predix-message-queue"

ANALYTIC_FRAMEWORK_SERVICE_INSTANCE_NAME="$INSTANCE_PREPENDER-af"
ANALYTIC_FRAMEWORK_SERVICE_NAME="predix-analytics-framework"
ANALYTIC_FRAMEWORK_SERVICE_PLAN="Free"

REDIS_INSTANCE_NAME="$INSTANCE_PREPENDER-redis"
# In case of multiple instances of redis
# carrot top ^ is regex to serach for instance of redix that starts with redis
REDIS_SERVICE_NAME_REG="^redis"
REDIS_SERVICE_NAME=""
REDIS_SERVICE_PLAN="shared-vm"

PREDIX_CACHE_INSTANCE_NAME="$INSTANCE_PREPENDER-cache"
# In case of multiple instances of redis
# carrot top ^ is regex to serach for instance of redix that starts with redis
PREDIX_CACHE_SERVICE_NAME="predix-cache"
PREDIX_CACHE_SERVICE_PLAN="Shared-R30"

#Predix Enable modbus configuration using Modbus simulator
ENABLE_MODBUS_SIMULATOR="true"

#Predix Machine SDK related variables
ECLIPSE_WINDOWS_32BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-win32.zip"
ECLIPSE_WINDOWS_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-win32-x86_64.zip"

ECLIPSE_MAC_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-macosx-cocoa-x86_64.tar.gz"
ECLIPSE_LINUX_32BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-linux-gtk.tar.gz"
ECLIPSE_LINUX_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz"

ECLIPSE_TAR_FILENAME="eclipse.tar.gz"

MACHINE_GROUP_ID="predix-machine-package"
ARTIFACT_ID="predixmachinesdk"
ARTIFACT_TYPE="zip"
MACHINE_SDK="$ARTIFACT_ID-$MACHINE_VERSION"
MACHINE_SDK_ZIP="$ARTIFACT_ID-$MACHINE_VERSION.$ARTIFACT_TYPE"

EDGE_MANAGER_URL="https://shared-tenant.edgemanager.run.asv-pr.ice.predix.io"
EDGE_MANAGER_UAA_URL="https://9274a009-9af1-4c5d-a0bb-dfe07771e29c.predix-uaa.run.asv-pr.ice.predix.io"
EDGE_MANAGER_SHARED_CLIENT_SECRET="c2hhcmVkLXRlbmFudC1hcHAtY2xpZW50Okk1NXpLbUFGMFNfQUdkbAo="
EDGE_DEVICE_NAME="$INSTANCE_PREPENDER-workshopedisondevice1"
EDGE_DEVICE_ID="$INSTANCE_PREPENDER-workshopedisondevice1"
EDGE_DEVICE_KIT_USER="gwuser"

PREDIX_KIT_PROPERTY_FILE="/etc/predix/predix.conf"
