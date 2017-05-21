#!/bin/bash

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

__try_create_service_using_cfcli() {
  echo "__try_create_service_using_cfcli $1 $2 $3 $4 $5"
  if __service_exists $3 ; then
    echo -n "Service $3 already exists" # Do nothing
  else
    echo -e "\n$ cf create-service $1 $2 $3 -c $4\n"
    if cf cs $1 $2 $3 -c $4; then
    	__append_new_line_log "$5 service instance successfully created!" "$logDir"
    else
    	__append_new_line_log "Couldn't create $5 service. Retrying..." "$logDir"
    	if cf cs $1 $2 $3 -c $4; then
    		__append_new_line_log "$5 service instance successfully created!" "$logDir"
    	else
    		__error_exit "Couldn't create $5 service instance..." "$logDir"
    	fi
    fi
  fi
}

__try_create_uaa() {
  if __service_exists $3 ; then
    echo -n "Service $3 already exists" # Do nothing
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

__try_create_predix_service() {
  echo "__try_create_predix_service $1 $2 $3 $4 $5 $6"
  px uaa login $4 admin --secret $6
  if __service_exists $3 ; then
    echo -n "Service $3 already exists" # Do nothing
  else
    echo -e "\n$ px create-service $1 $2 $3 $4 --client-id $5 --client-secret $6\n"
    if px cs $1 $2 $3 $4 --client-id $5 --client-secret $6; then
    	__append_new_line_log "$7 service instance successfully created!" "$logDir"
    else
    	__append_new_line_log "Couldn't create $7 service. Retrying..." "$logDir"
    	if px cs $1 $2 $3 $4 --client-id $5 --client-secret $6; then
    		__append_new_line_log "$7 service instance successfully created!" "$logDir"
    	else
    		__error_exit "Couldn't create $7 service instance..." "$logDir"
    	fi
    fi
  fi
}
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
	px a | grep $1 > /dev/null 2>&1
	return $?
}

__service_exists() {
	px s | grep $1 > /dev/null 2>&1
	return $?
}

__is_bound() {
  px s | grep $2 | grep $1 > /dev/null 2>&1
  return $?
}

function __get_login() {
  if [ "$INSTANCE_PREPENDER" == "" ]; then
    INSTANCE_PREPENDER=$(px target | grep -i 'User' | awk '{print $2}' | cut -d@ -f1)
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
