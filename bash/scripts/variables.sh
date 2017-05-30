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
WEBSOCKET_SERVER_APP_NAME="$INSTANCE_PREPENDER-websocket-server"
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

############### UAA Configurations ###############

# The username of the new user to authenticate with the application
UAA_USER_NAME="app_user_1"

# The email address of username above
UAA_USER_EMAIL="app_user_1@ge.com"

# The password of the user above
UAA_USER_PASSWORD="app_user_1"

# The secret of the Admin client ID (Administrator Credentails)
UAA_ADMIN_SECRET="secret"

# The generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_LOGIN="login_client_id"

# The generic client ID password
UAA_CLIENTID_LOGIN_SECRET="secret"

# The generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_GENERIC="app_client_id"

# The generic client ID password
UAA_CLIENTID_GENERIC_SECRET="secret"

# The machine generic client ID that will be created with necessary UAA scope/autherities
UAA_CLIENTID_DEVICE="device_client_id"

# The machine generic client ID password
UAA_CLIENTID_DEVICE_SECRET="secret"

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
TIMESERIES_INSTANCE_NAME="$INSTANCE_PREPENDER-time-series"

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

#Name of the Asset plan (eg: Free) - default already set
ASSET_SERVICE_PLAN="Free"

#Name of your Asset instance - default already set
ASSET_INSTANCE_NAME="$INSTANCE_PREPENDER-asset"


RABBITMQ_SERVICE_INSTANCE_NAME="$INSTANCE_PREPENDER-rmq"
RABBITMQ_SERVICE_PLAN="standard"
RABBITMQ_SERVICE_NAME="rabbitmq-36"

ANALYTIC_FRAMEWORK_SERVICE_INSTANCE_NAME="$INSTANCE_PREPENDER-af"
ANALYTIC_FRAMEWORK_SERVICE_NAME="predix-analytics-framework"
ANALYTIC_FRAMEWORK_SERVICE_PLAN="Free"

REDIS_INSTANCE_NAME="$INSTANCE_PREPENDER-redis"
REDIS_SERVICE_NAME="redis"
REDIS_SERVICE_PLAN="shared-vm"

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
