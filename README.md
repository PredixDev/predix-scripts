# Predix Application Quickstart
Quickstart to set up a Predix Application, including Predix Servies, and configure Predix Machine to have an edge device stream data to the Predix Cloud.

## Intro
Welcome Predix Developers! This product is a reference application for Predix that exposes various micro services for demo, quick setup, and configuration purposes. It has several use cases. One primary one is to push time series data from an edge device, either your local machine or any device such as Raspberry PI/Intel Edison,  to Predix Time Series Service and be viewable via the front-end which uses the Predix WebApp Starter. Run the `quickstart` script to setup a instance of time series, UAA, Asset and push a Front-End demo application to Cloud Foundry. This gives a basic idea of how various Predix micro services can be hooked together and configured quickly and easily.

The quickstart will produce 3 logs in a ./log directory. One is a generic log `quickstartlog.log`, another pertains to all things related Predix Service configuration and deployment called `predix-services-summary`, and lastly one that pertains to configuration and deployment of the frontend application called `build-basic-app-summary.txt`.

For more information about executing the script, run `./bash/quickstart.sh -h`.

## Development machine configurations and step-by-step to building Predix Application and Services

Before running the script, on your development machine (not your Raspberry PI or other edge device), please make sure that you install Cloud Foundry and have other environment prerequisites in place by completing the following steps.

1. Install CF CLI (Cloud Foundry Command Line Interface) from this website: https://github.com/cloudfoundry/cli.  
  a. Go to the Downloads Section of the README on the GitHub and download the correct package or binary for your operating system.
  b. Check that it is installed by typing `cf` on your command line.  

2. Be sure that CURL is installed on your machine
  1. Executing in your terminal `curl --version` should return a valid version number
  2. For Windows, this needs to be done by installing Cygwin
  3. Cywgin with Curl: http://stackoverflow.com/questions/3647569/how-do-i-install-curl-on-cygwin
  4. Necessary libraries include Python Language interpreter, unzip, vim editor, curl, dos2unix, and git distributed version control system

3. Be sure to set your environment proxy variables before trying to run the script.
```
export ALL_PROXY=http://<proxy-host>:<proxy-port>
export HTTP_PROXY=$ALL_PROXY
export HTTPS_PROXY=$ALL_PROXY
export http_proxy=$ALL_PROXY
export https_proxy=$ALL_PROXY
```

4. Be sure that you have added an SSH key to your ssh-agent and for your GitHub account. https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

5. Go to `/scripts/variables.sh`, and validate that you are able to git clone the repo found in the variable value `GIT_PREDIX_NODEJS_STARTER_URL`.
  1. Run `git clone {GIT_PREDIX_NODEJS_STARTER_URL}`. It is critical that you set up your ssh-agent correctly so that you are not prompted for your passphrase when cloning the repository.
  2. If unsuccessful, then replace the value with the value that is commented out and attempt to clone using this new value
  3. If still unsuccessful, the issue might be a proxy issue. Attempt to set a git proxy setting by following the steps found here: http://stackoverflow.com/questions/783811/getting-git-to-work-with-a-proxy-server
  4. Run `eval $(ssh-agent)`, and then `ssh-add` if you are prompted for a passphrase when cloning the repository.

6. Once the above steps are completed, you can start configuring the scripts.  Open the file `/scripts/variables.sh` in a text editor.  This file contains environment variables that are used in `quickstart.sh` and they need to be filled out before using the script. Services and plans are set to the default values for the Predix VPC. See the comments in the file for more information.
    1. By default, the Cloud Foundry Organization and the username is your email
    2. By default, no proxy host:port is set
    3. By default, the username used to login to the application is "sample"
    4. By default, the password used to login to the application is "sample_password"

7. Now you’re ready to run the scripts.

  1. Run `/scripts/cleanup.sh`. This script is responsible for deleting the applications and services created from the `quickstart.sh` script. It's okay if Cloud Foundry Failure messages come up on the console, the script will
  attempt to rerun the Cloud Foundry command another try and this tends to solve failures
  2. Type `./quickstart.sh`. First you will be prompted for your Cloud Foundry password. After that the script will begin setting up the various micro services, hooking them together using the parameters set in the `variables.sh` file.
  3. If any errors occurs during `quickstart.sh`, `cleanup.sh` will be ran.

8.	Upon completion, your Predix App has been set up and your Predix Machine is now ready to be ported over to
your edge device.
  1. More Documentation will follow here how to port it over, placeholder for now.

9.	After the script is complete, run the command 'cf apps' to see the list of cloud foundry apps you have created. Within that list the app pushed by the script will have the name set in the variables.sh file. Under the 'urls' heading in that apps' row the url used for the front-end will be available. Navigating to that url will show a time series graph representation of the simulation data displayed using the Predix Webapp Starter.

Congratulations! You have successfully created your first Predix Application! You are now a Predix Developer!


## Scripts and their operations
### variables.sh
This script contains the global variable values used by the most Scripts
### cleanup.sh
This script is responsible for deleting all applications, and service instances created from `quickstart.sh`
### build-basic-app.sh
This script is responsible for checking out, configuring, building, and pushing deploying the front end application to cloud foundry. The assumption is that the user has permissions to checkout the repo where the application lives in. Configurations are made to both the manifest.yml and config.json found in the repo specified in the script.
### predix_services_setup.sh
This script instantiates the following Predix services: Timeseries, Asset, and UAA. The script will also configure each service with the necessary authorities and scopes, create a UAA user, create UAA client id, and
post sample data to the Asset service.
### predix_machine_setup.sh
This script configures a Predix Machine Container with the values corresponding to the Predix Services and Predix Application created. It uses the helper method `machineconfig.sh`.
### quickstart.sh
This script performs the bulk of the work needed to set up the sample application.

1. We first login to Cloud Foundry and push a temp app that will allow us to create Predix Service instances and update their configurations such as scope, authorities and creating any required clients

2. We call the `predix_services_setup.sh` script, passing it the temp app pushed in step 1.

3. We call the `predix_machine_setup.sh` script, passing it the temp app pushed in step 1.

4. We call the `build-basic-app.sh` script, passing it the temp app pushed in step 1.

5. Lastly we delete the temp-app, push the now configured front-end-app, bind all necessary Predix Services to the app, and start the app.

### machineconfig.sh
This script will do a Find and Replace on the required configurations that need to be changed in order to have Predix Machine correctly push simulated data to the created Predix TimeSeries Service.
### curl_helper_funcs.sh
This script will hold a group of helper methods that will perform CURL commands
### error_handling_helper_funcs.sh
This script will hold a group of helper methods that will all for error handling (parameter number validation, etc..)
### files_helper_funcs.sh
This script will hold a group of helper methods that will perform File modification (appending, finding/replacing lines in files).

## Predix Scripts installers supported (as of 5/11/2018)
```
---------------------------------------- Setting the local to en-US for the quickstart script ----------------------------------------
arguments : -pxclimin 0.6.3 -ba -uaa -asset -ts -wd -nsts -mc -script build-basic-app.sh -script-readargs build-basic-app-readargs.sh
  COMMON CONFIGURATIONS:
    quickstartRootDir                        : /Users/212307911/internal/tmp/edge-simulator/predix-scripts
    APP_SCRIPT                               : build-basic-app.sh
    SCRIPT_READARGS                          : build-basic-app-readargs.sh
    BINDING_APP                              : 1
    BRANCH                                   : master
    CONTINUE_FROM                            : 0
    CONTINUE_FROM_SWITCH                     : 
    LOGIN                                    : 1
    INSTANCE_PREPENDER                       : 
    PREDIX_CLI_MIN                           : 0.6.3
    QUIET_MODE                               : 0
    RUN_COMPILE_REPO                         : 0
    RUN_DELETE_SERVICES                      : 0
    RUN_DELETE_APPS                          : 0
    SKIP_ALL_DONE                            : 1
    SKIP_BROWSER                             : 0
    SKIP_INTERACTIVE                         : 0

  BACK-END:
    MAVEN_SETTINGS_FILE                      : /Users/212307911/.m2/settings.xml
    VERIFY_MVN                               : 1
    VERIFY_ARTIFACTORY                       : 0


BUILD-BASIC-APP:
  SERVICES:
    CUSTOM_UAA_INSTANCE                      : 
    CUSTOM_ASSET_INSTANCE                    : 
    CUSTOM_TIMESERIES_INSTANCE               : 
    CUSTOM_EVENTHUB_INSTANCE                 : 
    CUSTOM_PREDIXCACHE_INSTANCE              : 
    RUN_CREATE_SERVICES                      : 0
    RUN_CREATE_ACS                           : 0
    RUN_CREATE_ASSET                         : 1
    RUN_CREATE_EVENT_HUB                     : 0
    RUN_CREATE_BLOBSTORE                     : 0
    RUN_CREATE_PREDIX_CACHE                  : 0
    RUN_CREATE_MOBILE                        : 0
    RUN_CREATE_MOBILE_REF_APP                : 0
    RUN_CREATE_TIMESERIES                    : 1
    RUN_CREATE_UAA                           : 1
    USE_TRAINING_UAA                         : 0

  ASSET-MODEL:
    RUN_CREATE_ASSET_MODEL_DEVICE1           : 0
    RUN_CREATE_ASSET_MODEL_RMD               : 0
    RUN_CREATE_ASSET_MODEL_RMD_METADATA_FILE : 
    RUN_CREATE_ASSET_MODEL_RMD_FILE          : 

  BACK-END:
    USE_DATAEXCHANGE                         : 0
    USE_DATA_SIMULATOR                       : 0
    USE_RMD_DATASOURCE                       : 0
    USE_WEBSOCKET_SERVER                     : 0
    USE_WINDDATA_SERVICE                     : 1

  FRONT-END:
    USE_DATAEXCHANGE_UI                      : 0
    USE_NODEJS_STARTER                       : 0
    USE_NODEJS_STARTER_W_TIMESERIES          : 1
    USE_MOBILE_STARTER                       : 0
    USE_POLYMER_SEED                         : 0
    USE_POLYMER_SEED_UAA                     : 0
    USE_POLYMER_SEED_ASSET                   : 0
    USE_POLYMER_SEED_TIMESERIES              : 0
    USE_POLYMER_SEED_RMD                     : 0

  MOBILE:
    USE_MOBILE_STARTER                       : 0

  MACHINE:
    PREDIX_MACHINE_HOME			     : /Users/212307911/internal/tmp/edge-simulator/predix-scripts/PredixMachineEdgeStarter
    RUN_MACHINE_CONFIG                       : 1
    RUN_CREATE_MACHINE_CONTAINER             : 0
    RUN_EDGE_MANAGER_SETUP                   : 
    MACHINE_VERSION                          : 17.1.3
    MACHINE_CONTAINER_TYPE                   : EdgeStarter
    RUN_MACHINE_TRANSFER                     : 0
    MACHINE_CUSTOM_IMAGE_NAME                : PredixMachineDebug
 ```
    
 [![Analytics](https://predix-beacon.appspot.com/UA-82773213-1/predix-scripts/readme?pixel)](https://github.com/PredixDev)

