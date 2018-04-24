#!/bin/bash

#	----------------------------------------------------------------
#	Function for binding an app to a service using the predix cli
#		Accepts 2 arguments:
#			1:string of app name
#			2:string of service instance name
#  Returns:
#     nothing
#	----------------------------------------------------------------
__try_bind() {
  if __is_bound $1 $2 ; then
    echo "$1 is already bound to $2" # Do nothing
  else
    echo -e "\n$ px bind-service $1 $2\n"
    if px bs $1 $2; then
    	__append_new_line_log "\"$2\" successfully bound to app \"$1\"!" "$logDir"
    else
    	if px bs $1 $2; then
        __append_new_line_log "\"$2\" successfully bound to app \"$1\"!" "$logDir"
      else
        __error_exit "There was an error binding \"$2\" to the app \"$1\"!" "$logDir"
      fi
    fi
  fi
}

__try_restage() {
  if px cf restage $1; then
      __append_new_line_log "\"$1\" Restage successful" "$logDir"
  else
      __append_new_line_log "\"$1\" Restage failed" "$logDir"
  fi
}

__try_setenv() {
  if px cf set-env $1 $2 $3; then
      __append_new_line_log "\"$1\" set-env successful" "$logDir"
  else
      __append_new_line_log "\"$1\" set-env failed" "$logDir"
  fi
}

#	----------------------------------------------------------------
#	Function for creating a predix service using the cf cli
#		Accepts 6 arguments:
#			1:string of service-name from predix marketplace
#			2:string of pricing plan from predix marketplace
#			3:string of the name you want to give the service instance
#			4:string of a json string for the -c switch
#			5:string of the name of the service to print for the log
#  Returns:
#     nothing
#	----------------------------------------------------------------
__try_create_service_using_cfcli() {
  __validate_num_arguments 5 $# "\"predix_funcs:__try_create_service_using_cfcli\" expected in order: service name, pricing plan, instance name, -c json string, service name for log" "$logDir"
  echo "__try_create_service_using_cfcli $1 $2 $3 $4 $5"

  if __service_exists $3 ; then
    echo "Service $3 already exists" # Do nothing
  else
    echo -e "\n$ cf create-service $1 $2 $3 -c '$4'\n"
    if cf cs $1 $2 $3 -c $4; then
    	__append_new_line_log "$5 service instance successfully created!" "$logDir"
    else
    	__append_new_line_log "Couldn't create $5 service. Retrying..." "$logDir"
    	if cf cs $redisName $2 $3 -c $4; then
    		__append_new_line_log "$5 service instance successfully created!" "$logDir"
    	else
    		__error_exit "Couldn't create $5 service instance..." "$logDir"
    	fi
    fi
  fi
}

__try_create_uaa() {
  if __service_exists $3 ; then
    echo "Service $3 already exists" # Do nothing
    px uaa login $UAA_INSTANCE_NAME admin --secret $UAA_ADMIN_SECRET
  else
    echo -e "\n$ px create-service $1 $2 $3 --admin-secret $4\n"
    if px cs $1 $2 $3 --admin-secret $4; then
    	__append_new_line_log "$5 service instance successfully created!" "$logDir"
    else
    	__append_new_line_log "Couldn't create $5 service. Retrying..." "$logDir"
    	if px cs $1 $2 $3 --admin-secret $4; then
    		__append_new_line_log "$5 service instance successfully created!" "$logDir"
    	else
    		__error_exit "Couldn't create $5 service instance..." "$logDir"
    	fi
    fi
  fi
}

#	----------------------------------------------------------------
#	Function for creating a predix service using the predix cli
#		Accepts 8 arguments:
#			1:string of service-name from predix marketplace
#			2:string of pricing plan from predix marketplace
#			3:string of the name you want to give the service instance
#			4:string of the uaa instance name as it appears in the org/space
#			5:string of the UAA admin account secret
#			6:string of the name of the clientid
#			7:string of the secret for the client id
#			8:string of the name of the service to print for the log
#  Returns:
#     nothing
#	----------------------------------------------------------------
__try_create_predix_service() {
  __validate_num_arguments 8 $# "\"predix_funcs:__try_create_predix_service\" expected in order: service name, pricing plan, instance name, uaa name, admin secret, clientid, client secret, service name for log" "$logDir"
  echo "__try_create_predix_service $1 $2 $3 $4 $5 $6 $7"
  service=$1
  plan=$2
  instance=$3
  uaa_instance=$4
  admin_secret=$5
  client=$6
  client_secret=$7
  name=$8

  #
  px uaa login $uaa_instance admin --secret $admin_secret
  if __service_exists $instance ; then
    echo "Service $instance already exists" # Do nothing
  else
    if [[ $client == \"\" ]]; then
      echo -e "\n$ px create-service $service $plan $instance $uaa_instance --client-secret $client_secret\n"
      if [[ $client_secret == \"\" ]]; then
        if px cs $service $plan $instance $uaa_instance ; then
      	   __append_new_line_log "$name service instance successfully created!" "$logDir"
        else
      	   __append_new_line_log "Couldn't create $name service. Retrying..." "$logDir"
      	   if px cs $service $plan $instance $uaa_instance ; then
      		     __append_new_line_log "$name service instance successfully created!" "$logDir"
      	   else
      		     __error_exit "Couldn't create $name service instance..." "$logDir"
      	   fi
        fi
      else
        if px cs $service $plan $instance $uaa_instance --client-secret $client_secret; then
      	   __append_new_line_log "$name service instance successfully created!" "$logDir"
        else
      	   __append_new_line_log "Couldn't create $name service. Retrying..." "$logDir"
      	   if px cs $service $plan $instance $uaa_instance --client-secret $client_secret; then
      		     __append_new_line_log "$name service instance successfully created!" "$logDir"
      	   else
      		     __error_exit "Couldn't create $name service instance..." "$logDir"
      	   fi
        fi
      fi
    else
      echo -e "\n$ px create-service $service $plan $instance $uaa_instance --client-id $client --client-secret $7\n"
      if px cs $service $plan $instance $uaa_instance --client-id $client --client-secret $client_secret; then
    	   __append_new_line_log "$name service instance successfully created!" "$logDir"
      else
    	   __append_new_line_log "Couldn't create $name service. Retrying..." "$logDir"
    	   if px cs $service $plan $instance $uaa_instance --client-id $client --client-secret $client_secret; then
    		     __append_new_line_log "$name service instance successfully created!" "$logDir"
    	   else
    		     __error_exit "Couldn't create $name service instance..." "$logDir"
    	   fi
      fi
    fi
  fi
}

#	----------------------------------------------------------------
#	Function for creating a predix mobile service using the predix cli
#		Accepts 8 arguments:
#			1:string of service-name from predix marketplace
#			2:string of pricing plan from predix marketplace
#			3:string of the name you want to give the service instance
#			4:string of the uaa instance name as it appears in the org/space
#			5:string of the UAA admin account secret
#     6:string of the UAA user name (mobile deveoper)
#     7:string of the UAA user email
#     8:string of the UAA user password
#		  9:string of the name of the service to print for the log
#  Returns:
#     nothing
#	----------------------------------------------------------------
__try_create_predix_mobile_service() {
  __validate_num_arguments 11 $# "\"predix_funcs:__try_create_predix_mobile_service\" expected in order: service name, pricing plan, instance name, uaa name, admin secret, username, email, user password, service name, oauth api client, oauth api secret for log" "$logDir"
  echo "__try_create_predix_mobile_service $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11}"
  service=$1
  plan=$2
  instance=$3
  uaa_instance=$4
  admin_secret=$5
  dev_user=$6
  user_email=$7
  user_password=$8
  oauthapiclient=$9
  oauthapiclientsecret=${10}
  name=${11}

  px uaa login $uaa_instance admin --secret $admin_secret
  if __service_exists $instance ; then
    echo -n "Service $instance already exists" # Do nothing
  else
    echo -e "\n$ px create-service $service $plan $instance $uaa_instance -d $dev_user -e $user_email -p $user_password --oauth-api-client $oauthapiclient --oauth-api-client-secret $oauthapiclientsecret \n"
    if px create-service $service $plan $instance $uaa_instance -d $dev_user -e $user_email -p $user_password --oauth-api-client $oauthapiclient --oauth-api-client-secret $oauthapiclientsecret ; then
        __append_new_line_log "$name service instance successfully created!" "$logDir"
    # else
      # __append_new_line_log "Couldn't create $name service. Retrying..." "$logDir"

      # if [[ $RUN_DELETE_SERVICES -eq 1 ]]; then
    	#    __try_delete_service $instance
    	# fi
      # if px create-service $service $plan $instance $uaa_instance -d $dev_user -e $user_email -p $user_password --oauth-api-client $oauthapiclient --oauth-api-client-secret $oauthapiclientsecret ; then
      #   __append_new_line_log "$name service instance successfully created!" "$logDir"
      # else
      #   __error_exit "Couldn't create $name service instance..." "$logDir"
      # fi
    fi
  fi
}

__try_create_af_service() {
  px uaa login $4 admin --secret $7
  if __service_exists $3 ; then
    echo -n "Service $3 already exists" # Do nothing
  else
        __analytic_framework_ui_user_delete ${12}

      	#echo -e "\n$here px create-service $1 $2 $3 $4 $5 $6 --admin-secret $7 --runtime-client-id $8 --runtime-client-secret $9 --ui-client-id ${10} --ui-client-secret ${11} --ui-user ${12} --ui-user-password ${13} --ui-user-email ${14} --ui-domain-prefix ${15}\n"
      	echo -e "\n$here px create-service $1 --admin-secret $7 --runtime-client-id $8 --runtime-client-secret $9 --ui-client-id ${10} --ui-client-secret ${11} --ui-user ${12} --ui-user-password ${13} --ui-user-email ${14} --ui-domain-prefix ${15} $2 $3 $4 $5 $6\n"
      	#if px cs $1 $2 $3 $4 --runtime-client-id $6 --runtime-client-secret $7 --ui-client-id "iaf" --ui-client-secret "secret" --ui-domain-prefix "iaf"; then
      	if px create-service $1 --admin-secret $7 --runtime-client-id $8 --runtime-client-secret $9 --ui-client-id ${10} --ui-client-secret ${11} --ui-user ${12} --ui-user-password ${13} --ui-user-email ${14} --ui-domain-prefix ${15} $2 $3 $4 $5 $6; then
    	   __append_new_line_log "$3 service instance successfully created!" "$logDir"
      	else
    	   __error_exit "Couldn't create $3 service instance..." "$logDir"
      	fi
  fi
}

#	----------------------------------------------------------------
#	Function for unbinding an app from a service using the predix cli
#		Accepts 2 arguments:
#			1:string of app name
#			2:string of service instance name
#  Returns:
#     nothing
#	----------------------------------------------------------------
__try_unbind() {
	if __app_exists $1 && __is_bound $1 $2; then
    echo -e "\n$ px unbind-service $1 $2\n"
		if px us $1 $2; then
	  	__append_new_line_log "Successfully unbound \"$2\" from \"$1\"" "$logDir"
		else
	  	__append_new_line_log "Failed to undind \"$2\" from \"$1\"" "$logDir"
		fi
	fi
}

__try_delete_app() {
	if __app_exists $1; then
    echo -e "\n$ px delete $1 -f -r\n"
		if px d $1 -f -r; then
		  __append_new_line_log "Successfully deleted \"$1\"" "$logDir"
		else
		  __append_new_line_log "Failed to delete \"$1\". Retrying..." "$logDir"
		  if px d $1 -f -r; then
		    __append_new_line_log "Successfully deleted \"$1\"" "$logDir"
		  else
		    __append_new_line_log "Failed to delete \"$1\". Giving up." "$logDir"
		  fi
		fi
	fi
}

__try_delete_service() {
  echo "deletingService $1"
  if boundApps=$(px s | grep $1 | tr -s ' ' | cut -d' ' -f4- ); then
    echo -n "" # Do nothing
  else
    __error_exit "There was an error getting BOUND_APPS..." "$logDir"
  fi
  for app in $boundApps
  do
    app=$(echo "$app" | cut -d',' -f1)
    echo $app
    if __app_exists $app ; then
      __try_unbind $app $1
    fi
  done

	if __service_exists $1; then
    echo -e "\n$ px delete-service $1 -f\n"
		if px ds $1 -f; then
		  __append_new_line_log "Successfully deleted \"$1\"" "$logDir"
		else
		  __append_new_line_log "Failed to delete \"$1\". Retrying..." "$logDir"
		  if px d $1 -f; then
		    __append_new_line_log "Successfully deleted \"$1\"" "$logDir"
		  else
		    __append_new_line_log "Failed to delete \"$1\". Giving up." "$logDir"
		  fi
		fi
	fi
}

__app_exists() {
	px app $1 > /dev/null 2>&1
	return $?
}

__service_exists() {
	px service $1 > /dev/null 2>&1
	if [ $? -eq 1 ]; then
	  echo "px service $1 failed to find service"
	  #px service $1
	  return 1
	fi
	return $?
}

__analytic_framework_ui_user_exists() {
	px uaa users | grep $1 > /dev/null 2>&1
	return $?
}

__analytic_framework_ui_user_delete() {
	if __analytic_framework_ui_user_exists $1; then
		px uaa user delete $1 > /dev/null 2>&1
	fi
}

__is_bound() {
  px s | grep $2 | grep $1 > /dev/null 2>&1
  return $?
}

function __get_login() {
  if [ "$INSTANCE_PREPENDER" == "" ]; then
    INSTANCE_PREPENDER=$(px target | grep -i 'User' | awk '{print $2}' | cut -d@ -f1 | tr -dc '[:alnum:]\n\r')
    export INSTANCE_PREPENDER
  fi
}

function __verifyPxLogin() {
  set +e
  local targetInfo
  targetInfo=$(predix target)
  set -e

  if [[ "${targetInfo/FAILED}" == "$targetInfo" ]] && [[ "${targetInfo/No org}" == "$targetInfo" ]] && [[ "${targetInfo/No space}" == "$targetInfo" ]]; then
    predix target
    echo ""
    echo "Looks like you are already logged in."
    __pause
  else
    echo "Please login..."
    predix login
  fi
}

function __predix_kit_admin_group_exists() {
	px uaa groups | grep $1 > /dev/null 2>&1
	return $?
}

function __predix_kit_admin_group_membeship_exists() {
	px uaa members $1 | grep $2 > /dev/null 2>&1
	return $?
}

# Predix Kit create a admin user
function __predix_kit_admin_user_create() {
  echo ""
  echo "Checking on Kit Admin User "
	if px uaa user get $1; then
    echo "Deleting old Kit Admin User"
		px uaa user delete $1 > /dev/null 2>&1
 	fi
  echo "Creating Kit Admin User $KIT_ADMIN_USER_NAME $KIT_ADMIN_USER_EMAIL $KIT_ADMIN_PASSWORD"
  px uaa user create $1  --emails $2 --password $3
}

# Predix Kit add admin user to the uaa group - membership managment  $KIT_ADMIN_GROUP $KIT_ADMIN_USER_NAME
function __predix_kit_admin_group_membership_setup() {
  if __predix_kit_admin_group_exists $1; then
   echo ""
   echo "Looks like predix kit admin group exists."
  else
    echo ""
    echo "Creating predix kit admin group"
    px uaa group create $1
 	fi
  if __predix_kit_admin_group_membeship_exists $1 $2; then
      echo ""
      echo "Looks like you are member of the predix kit admin Group."
  else
      px uaa member add $1 $2
	fi
}
function __predix_kit_admin_client_exists() {
	px uaa client get $1 | grep $2 > /dev/null 2>&1
	return $?
}

# Predix Kit client managment
function __predix_kit_admin_client_setup() {
  echo "Please add the predixkit.admin scope and authority to app_client_id using UAA Dashboard or Predix Toolkit."
}
