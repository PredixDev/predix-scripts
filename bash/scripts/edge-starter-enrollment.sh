#!/bin/bash

set -e

trap "trap_ctrlc" 2

DEVICE_ID="$1"
DEVICE_SECRET="$2"
DEVICE_ENROLLMENT_URL="$3"

curl http://localhost/api/v1/host/enroll \
    --unix-socket /var/run/edge-core/edge-core.sock \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{
            \"sharedSecret\": \"$DEVICE_SECRET\",
            \"deviceId\": \"$DEVICE_ID\",
            \"enrollmentUrl\": \"$DEVICE_ENROLLMENT_URL\"
        }"
