#echo "Front-end App Login: app_user_1/App_User_111" > foo.txt

# RUN_CREATE_CACHE=1

# if [[ $RUN_CREATE_CACHE -eq 1 ]]; then
#   echo "equal to one"
# fi

#    Set the timeseries and asset information to query the services
# if [[ "$USE_WINDDATA_SERVICE" == "1" ]]; then
#   getUrlForAppName $WINDDATA_SERVICE_APP_NAME WINDDATA_SERVICE_URL "https"
#   __find_and_replace "\#windServiceURL: .*" "windServiceURL: $WINDDATA_SERVICE_URL" "manifest.yml" "$logDir"
# fi
PROXY_HOST_PORT=$(echo $http_proxy | awk -F"//" '{print $2}')

if [[ -z "$PROXY_HOST_PORT" ]]; then
  PROXY_HOST_PORT=$(echo $https_proxy | awk -F"//" '{print $2}')
fi
if [[ -z "$PROXY_HOST_PORT" ]]; then
  PROXY_HOST_PORT=$(echo $HTTP_PROXY | awk -F"//" '{print $2}')
fi
if [[ -z "$PROXY_HOST_PORT" ]]; then
  PROXY_HOST_PORT=$(echo $HTTPS_PROXY | awk -F"//" '{print $2}')
fi

PROXY_HOST=$(echo $PROXY_HOST_PORT | awk -F":" '{print $1}')
PROXY_PORT=$(echo $PROXY_HOST_PORT | awk -F":" '{print $2}')

echo "PROXY_HOST : $PROXY_HOST"
echo "PROXY_PORT : $PROXY_PORT"
