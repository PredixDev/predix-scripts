#!/bin/bash

for ROUTE in `cf curl "/v2/routes" | jq -r ".resources[].metadata.guid"`; do
  SPACE_GUID=$(cf curl "/v2/routes/$ROUTE" | jq -r ".entity.space_guid")

  SPACE_INFO=$(cf curl "/v2/spaces/$SPACE_GUID")
  SPACE_NAME=$(echo $SPACE_INFO | jq -r ".entity.name")
  ORG_GUID=$(echo $SPACE_INFO | jq -r ".entity.organization_guid")
  ORG_NAME=$(cf curl /v2/organizations/$ORG_GUID | jq -r ".entity.name")

  echo "Route:" $ROUTE "Org Name: " $ORG_NAME "Space Name: " $SPACE_NAME
done
