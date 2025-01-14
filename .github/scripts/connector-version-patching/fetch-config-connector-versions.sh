#!/bin/bash

echo "--- START SCRIPT ---"

CONNECTOR_PLUGINS_LIST_CONFIG="$(yq eval -o=json '.spec.build.onDemand.plugins.confluentHub' $KAFKA_CONNECT_BASE_CONFIGURATION_FILE)"

CONNECTOR_COUNT="$(echo "$CONNECTOR_PLUGINS_LIST_CONFIG" | jq length)"
echo "Connector Count: $CONNECTOR_COUNT"

CONNECTOR_PACKAGE_LIST=""
CONNECTOR_OWNER_LIST=""
CONNECTOR_VERSION_LIST=""

for ((i=0; i<CONNECTOR_COUNT; i++));
do
    CONNECTOR_NAME="$(echo "$CONNECTOR_PLUGINS_LIST_CONFIG" | jq --raw-output --argjson index "$i" '.[$index] | .name')"
    CONNECTOR_OWNER="$(echo "$CONNECTOR_PLUGINS_LIST_CONFIG" | jq --raw-output --argjson index "$i" '.[$index] | .owner')"
    CONNECTOR_VERSION="$(echo "$CONNECTOR_PLUGINS_LIST_CONFIG" | jq --raw-output --argjson index "$i" '.[$index] | .version')"
    echo "$i = [ Name: $CONNECTOR_NAME , Owner: $CONNECTOR_OWNER , Version: $CONNECTOR_VERSION ]"

    if [ -z "$CONNECTOR_PACKAGE_LIST" ];
    then
        CONNECTOR_PACKAGE_LIST="$CONNECTOR_NAME"
    else
        CONNECTOR_PACKAGE_LIST+=" $CONNECTOR_NAME"
    fi

    if [ -z "$CONNECTOR_OWNER_LIST" ];
    then
        CONNECTOR_OWNER_LIST="$CONNECTOR_OWNER"
    else
        CONNECTOR_OWNER_LIST+=" $CONNECTOR_OWNER"
    fi

    if [ -z "$CONNECTOR_VERSION_LIST" ];
    then
        CONNECTOR_VERSION_LIST="$CONNECTOR_VERSION"
    else
        CONNECTOR_VERSION_LIST+=" $CONNECTOR_VERSION"
    fi
done
