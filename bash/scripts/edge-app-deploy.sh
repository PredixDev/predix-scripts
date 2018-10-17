#!/bin/sh
#NOTE: this is a copy of the Predix Edge /opt/edge-agent/app-deploy script as of 10/16/18

#********************************************************************************
#   Synopsis:   app-deploy <app_name>
#
#   Purpose:
#       Deploy an application to the edge device.
#       This deploys the application, and creates the folder
#       /var/lib/edge-agent/<app_name>/docker where the application files will be
#       stored.
#       The tar container images will be extracted from the app_file_path and
#       will be loaded into docker and removed from the file system once loaded.
#
#*********************************************************************************

set -e

usage_and_exit() {
     >&2 echo "usage: $(basename $0) [--enable-core-api] <app_name> <app_file_path>"
    exit 1
}

EA_DIR=${EA_DIR:-/var/lib/edge-agent}
EA_CONFIG=${EA_CONFIG:-/opt/edge-agent/agent-data.json}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/var/lib/edge-agent/tmp}
#bin_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bin_dir=/opt/edge-agent
ENABLE_CORE_API=false

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
   usage_and_exit
fi

while [ $# -gt 2 ]; do
    key="$1"
    case $key in
        --enable-core-api)
            ENABLE_CORE_API=true
            shift # past argument
            ;;
        *)  # unknown option
            usage_and_exit
            ;;
    esac
done

APP_NAME="$1"
APP_FILE_PATH="$2"

${bin_dir}/validate-app-instance-id "$APP_NAME"

APP_DIR=${EA_DIR}/app/${APP_NAME}
APP_DOCKER_DIR=${APP_DIR}/docker
APP_CONF_DIR=${APP_DIR}/conf
APP_DATA_DIR=${APP_DIR}/data
EXTRACT_DIR=${DOWNLOAD_DIR}/$(cat /proc/sys/kernel/random/uuid)

cleanup() {
    if [ $? != 0 ]; then
      rm -rf $APP_DIR 2> /dev/null
      rm -rf $EXTRACT_DIR 2> /dev/null
    fi
}
trap cleanup EXIT

# remove app if it has already been deployed.
if [ -d "${APP_DIR}" ]; then
    ${bin_dir}/app-stop "--appInstanceId=${APP_NAME}"
fi

ENFORCE_SIGNING=${ENFORCE_SIGNING:-$(jq .enforce_signing "$EA_CONFIG")}

if [ "$ENFORCE_SIGNING" = "true" ]; then
    SIGNING_ROOT_KEY=${SIGNING_ROOT_KEY:-$(jq -r .signing_root_key "$EA_CONFIG")}

    set +e
    VERIFY_SIGNATURE="$(TEMP_PREFIX=$EA_DIR $bin_dir/signing-util verify_app -p "$APP_FILE_PATH" -k \
                        "$SIGNING_ROOT_KEY")"
    VERIFY_SIGNATURE_RESULT=$?
    if [ $VERIFY_SIGNATURE_RESULT -ne 0 ] && [ "$("$bin_dir/app-allow-third-party" --status)" = "on" ]; then
        VERIFY_SIGNATURE="$(TEMP_PREFIX=$EA_DIR $bin_dir/signing-util verify_app -p "$APP_FILE_PATH" -k \
                        "$SIGNING_ROOT_KEY" -t)"
        VERIFY_SIGNATURE_RESULT=$?
    fi
    set -e

    if [ $VERIFY_SIGNATURE_RESULT -ne 0 ]; then
        echo "ERROR: $APP_FILE_PATH has invalid signature: $VERIFY_SIGNATURE" >&2
        exit 1;
    fi
fi

# create the associated directories for the app being deployed.
mkdir -p "${APP_DIR}"
mkdir -p "${APP_DOCKER_DIR}"
mkdir -p "${APP_CONF_DIR}"
mkdir -p "${APP_DATA_DIR}"
chmod 777 "${APP_DATA_DIR}"
mkdir -p "${EXTRACT_DIR}"

# extract images from the provided app file.
tar -xzf "${APP_FILE_PATH}" -C "${EXTRACT_DIR}" > /dev/null

# check that the docker compose file exists
if ! test -f "${EXTRACT_DIR}/docker-compose.yml"
then
    echo "Invalid application bundle; docker-compose.yml file not found." >&2
    exit 1
fi

# check that the docker compose is valid
"${bin_dir}/validate-compose-file" "${EXTRACT_DIR}/docker-compose.yml"

# pre-process docker compose file
INSTALL_OPTS=""
if [ ${ENABLE_CORE_API} = true ]; then
    INSTALL_OPTS="--enable-core-api"
fi
"${bin_dir}/install-compose-file" ${INSTALL_OPTS} ${APP_DIR} "${EXTRACT_DIR}/docker-compose.yml" \
                     "${APP_DOCKER_DIR}/docker-compose.yml"

# load extracted images if available
result=$(ls "${EXTRACT_DIR}"/*.tar 2>/dev/null) && {
      if [ $? -eq 0 ]; then
          echo $result | xargs -n1 docker load -q -i
      fi
}

# deploy the app
cd ${APP_DIR}; docker stack deploy -c "${APP_DOCKER_DIR}"/docker-compose.yml "${APP_NAME}"

#remove docker image files from disk and extract directory
rm -rf "${EXTRACT_DIR}"
