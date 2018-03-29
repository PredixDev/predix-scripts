echo "Front-end App Login: app_user_1/App_User_111" > foo.txt

# RUN_CREATE_CACHE=1

# if [[ $RUN_CREATE_CACHE -eq 1 ]]; then
#   echo "equal to one"
# fi

#    Set the timeseries and asset information to query the services
# if [[ "$USE_WINDDATA_SERVICE" == "1" ]]; then
#   getUrlForAppName $WINDDATA_SERVICE_APP_NAME WINDDATA_SERVICE_URL "https"
#   __find_and_replace "\#windServiceURL: .*" "windServiceURL: $WINDDATA_SERVICE_URL" "manifest.yml" "$logDir"
# fi