# Predix Cloud Foundry Credentials
# Keep all values inside double quotes

#########################################################
# Mandatory User configurations that need to be updated
#########################################################

############## Proxy Configurations #############

# Proxy settings in format proxy_host:proxy_port
# Leave as is if no proxy
ALL_PROXY=":8080"

############## Front-end Configurations #############
# Name for your Frone End Application
FRONT_END_APP_NAME="$INSTANCE_PREPENDER-nodejs-starter"
WINDDATA_SERVICE_APP_NAME="$INSTANCE_PREPENDER-winddata-service"

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
UAA_CLIENTID_GENERIC="app_client_id"

# The generic client ID password
UAA_CLIENTID_GENERIC_SECRET="secret"

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

# GITHUB repo to pull predix-nodejs-starter
GIT_PREDIX_NODEJS_STARTER_URL="https://github.com/PredixDev/predix-nodejs-starter.git"

GIT_PREDIX_WINDDATA_SERVICE_URL="https://github.com/PredixDev/winddata-timeseries-service.git"

# Name for the temp_app application
TEMP_APP="$INSTANCE_PREPENDER-hello-world"
TEMP_APP_GIT_HUB_URL="https://github.com/PredixDev/Predix-HelloWorld-WebApp.git"

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
UAA_INSTANCE_NAME="$INSTANCE_PREPENDER-uaa"

############# Predix TimeSeries Configurations ##############

#The name of the TimeSeries service you are binding to - default already set
TIMESERIES_SERVICE_NAME="predix-timeseries"

#Name of the TimeSeries plan (eg: Free) - default already set
TIMESERIES_SERVICE_PLAN="Free"

#Name of your TimeSeries instance - default already set
TIMESERIES_INSTANCE_NAME="$INSTANCE_PREPENDER-time-series"

############# Predix Asset Configurations ##############

#The name of the Asset service you are binding to - default already set
ASSET_SERVICE_NAME="predix-asset"

#Name of the Asset plan (eg: Free) - default already set
ASSET_SERVICE_PLAN="Free"

#Name of your Asset instance - default already set
ASSET_INSTANCE_NAME="$INSTANCE_PREPENDER-asset"

#Predix Enable modbus configuration using Modbus simulator
ENABLE_MODBUS_SIMULATOR="true"

#Device Specific Connection info
DEVICE_SPECIFIC_GITHUB_REPO_NAME="predix-machine-template-adapter-edison"
MACHINE_TEMPLATES_GITHUB_REPO_URL="https://github.com/PredixDev/predix-machine-templates.git"


#Predix Machine SDK related variables
ECLIPSE_WINDOWS_32BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-win32.zip"
ECLIPSE_WINDOWS_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-win32-x86_64.zip"

ECLIPSE_MAC_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-macosx-cocoa-x86_64.tar.gz"
ECLIPSE_LINUX_32BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-linux-gtk.tar.gz"
ECLIPSE_LINUX_64BIT="http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz"

ECLIPSE_TAR_FILENAME="eclipse.tar.gz"

MACHINE_GROUP_ID="predix-machine-package"
ARTIFACT_ID="predixmachinesdk"
MACHINE_VERSION="16.3.1"
ARTIFACT_TYPE="zip"
MACHINE_SDK="$ARTIFACT_ID-$MACHINE_VERSION"
MACHINE_SDK_ZIP="$ARTIFACT_ID-$MACHINE_VERSION.$ARTIFACT_TYPE"
