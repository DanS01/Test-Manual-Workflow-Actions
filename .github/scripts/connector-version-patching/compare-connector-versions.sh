#!/bin/bash

echo "--- START SCRIPT ---"

echo "Connector Count: $CONNECTOR_COUNT"
echo "Connector Package List: $CONNECTOR_PACKAGE_LIST"
CONNECTOR_PACKAGE_LIST=($CONNECTOR_PACKAGE_LIST)
echo "Connector Versions: $CONNECTOR_VERSIONS"
CONNECTOR_VERSIONS=($CONNECTOR_VERSIONS)
echo "Connector Versions Confluent Hub: $CONNECTOR_VERSIONS_CONFLUENTHUB"
CONNECTOR_VERSIONS_CONFLUENTHUB=($CONNECTOR_VERSIONS_CONFLUENTHUB)

CONNECTOR_NAMES_TO_PATCH=""

for ((i=0; i<$CONNECTOR_COUNT; i++));
do
    echo "$i = [ Name: ${CONNECTOR_PACKAGE_LIST[$i]} , Config Version: ${CONNECTOR_VERSIONS[$i]} , Confluent Hub Version: ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]} ]"

    if [ "${CONNECTOR_VERSIONS[$i]}" != "${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}" ];
    then
        echo "Versions are different"

        if [ -z "$CONNECTOR_NAMES_TO_PATCH" ];
        then
            CONNECTOR_NAMES_TO_PATCH="${CONNECTOR_PACKAGE_LIST[$i]}"
        else
            CONNECTOR_NAMES_TO_PATCH+=" ${CONNECTOR_PACKAGE_LIST[$i]}"
        fi
    else
        echo "Versions are the same"

        if [ -z "$CONNECTOR_NAMES_TO_PATCH" ];
        then
            CONNECTOR_NAMES_TO_PATCH="NULL"
        else
            CONNECTOR_NAMES_TO_PATCH+=" NULL"
        fi
    fi
done

echo ""
echo "List of connectors to be patched:"
CONNECTOR_NAMES_TO_PATCH_DISPLAY=($CONNECTOR_NAMES_TO_PATCH)
for ((i=0; i<$CONNECTOR_COUNT; i++));
do
    if [ "${CONNECTOR_NAMES_TO_PATCH_DISPLAY[$i]}" != "NULL" ];
    then
        echo "${CONNECTOR_NAMES_TO_PATCH_DISPLAY[$i]}"
    fi
done
