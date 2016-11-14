#!/bin/bash
__try_bind() {
  if __is_bound $1 $2 ; then
    echo -n "" # Do nothing
  else
    echo -e "\n$ cf bind-service $1 $2\n"
    if cf bs $1 $2; then
    	__append_new_line_log "\"$2\" successfully bound to app \"$1\"!" "$predixServicesLogDir"
    else
    	if cf bs $1 $2; then
        __append_new_line_log "\"$2\" successfully bound to app \"$1\"!" "$predixServicesLogDir"
      else
        __error_exit "There was an error binding \"$2\" to the app \"$1\"!" "$predixServicesLogDir"
      fi
    fi
  fi
}

__try_create_service() {
  if __service_exists $3 ; then
    echo -n "" # Do nothing
  else
    echo -e "\n$ cf create-service $1 $2 $3 -c $4\n"
    if cf cs $1 $2 $3 -c $4; then
    	__append_new_line_log "$5 service instance successfully created!" "$predixServicesLogDir"
    else
    	__append_new_line_log "Couldn't create $5 service. Retrying..." "$predixServicesLogDir"
    	if cf cs $1 $2 $3 -c $4; then
    		__append_new_line_log "$5 service instance successfully created!" "$predixServicesLogDir"
    	else
    		__error_exit "Couldn't create $5 service instance..." "$predixServicesLogDir"
    	fi
    fi
  fi
}

__try_unbind() {
	if __app_exists $1 && __is_bound $1 $2; then
    echo -e "\n$ cf unbind-service $1 $2\n"
		if cf us $1 $2; then
	  	__append_new_line_log "Successfully unbinded \"$2\" from \"$1\"" "$cleanUpLogDirectory"
		else
	  	__append_new_line_log "Failed to unbind \"$2\" from \"$1\"" "$cleanUpLogDirectory"
		fi
	fi
}

__try_delete_app() {
	if __app_exists $1; then
    echo -e "\n$ cf delete $1 -f -r\n"
		if cf d $1 -f -r; then
		  __append_new_line_log "Successfully deleted \"$1\"" "$cleanUpLogDirectory"
		else
		  __append_new_line_log "Failed to delete \"$1\". Retrying..." "$cleanUpLogDirectory"
		  if cf d $1 -f -r; then
		    __append_new_line_log "Successfully deleted \"$1\"" "$cleanUpLogDirectory"
		  else
		    __append_new_line_log "Failed to delete \"$1\". Giving up." "$cleanUpLogDirectory"
		  fi
		fi
	fi
}

__try_delete_service() {
	if __service_exists $1; then
    echo -e "\n$ cf delete-service $1 -f\n"
		if cf ds $1 -f; then
		  __append_new_line_log "Successfully deleted \"$1\"" "$cleanUpLogDirectory"
		else
		  __append_new_line_log "Failed to delete \"$1\". Retrying..." "$cleanUpLogDirectory"
		  if cf d $1 -f; then
		    __append_new_line_log "Successfully deleted \"$1\"" "$cleanUpLogDirectory"
		  else
		    __append_new_line_log "Failed to delete \"$1\". Giving up." "$cleanUpLogDirectory"
		  fi
		fi
	fi
}

__app_exists() {
	cf a | grep $1 > /dev/null 2>&1
	return $?
}

__service_exists() {
	cf s | grep $1 > /dev/null 2>&1
	return $?
}

__is_bound() {
  cf s | grep $2 | grep $1 > /dev/null 2>&1
  return $?
}
