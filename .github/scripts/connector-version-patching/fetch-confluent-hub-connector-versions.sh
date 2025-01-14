#!/bin/bash

echo "--- START SCRIPT ---"

echo "Connector Count: $CONNECTOR_COUNT"
echo "Connector Package List: $CONNECTOR_PACKAGE_LIST"
#CONNECTOR_PACKAGE_LIST=($CONNECTOR_PACKAGE_LIST)
read -a CONNECTOR_PACKAGE_LIST <<< "$CONNECTOR_PACKAGE_LIST"
echo "Connector Owners: $CONNECTOR_OWNERS"
#CONNECTOR_OWNERS=($CONNECTOR_OWNERS)
read -a CONNECTOR_OWNERS <<< "$CONNECTOR_OWNERS"
echo "Connector Versions: $CONNECTOR_VERSIONS"
#CONNECTOR_VERSIONS=($CONNECTOR_VERSIONS)
read -a CONNECTOR_VERSIONS <<< "$CONNECTOR_VERSIONS"

CONNECTOR_VERSION_LIST_CONFLUENTHUB=""

for ((i=0; i<CONNECTOR_COUNT; i++));
do
    if [ -n "$CONNECTOR_VERSION_LIST_CONFLUENTHUB" ];
    then
        echo ""
    fi
    echo "Fetching ${CONNECTOR_PACKAGE_LIST[$i]} connector version from Confluent Hub..."

    CONFLUENT_HUB_CONNECTOR_PAGE=$(curl --silent -L "https://www.confluent.io/hub/${CONNECTOR_OWNERS[$i]}/${CONNECTOR_PACKAGE_LIST[$i]}")
    VERSION_HTML_LINE=$(echo "$CONFLUENT_HUB_CONNECTOR_PAGE" | grep "Version ")

    # The substrings to use for matching and processing that result in the output being the string in-between these substrings
    stringVersionStart="Version <!-- -->"
    stringVersionEnd="</div>"

    VERSION="${VERSION_HTML_LINE#*${stringVersionStart}}"
    VERSION="${VERSION//${stringVersionEnd}*}"
    echo "Confluent Hub Version: $VERSION"

    if [ "${CONNECTOR_PACKAGE_LIST[$i]}" = "kafka-connect-jdbc" ];
    then
        VERSION="10.8.2"
        echo "Version Override: $VERSION"
    fi
    if [ "${CONNECTOR_PACKAGE_LIST[$i]}" = "connect-transforms" ];
    then
        VERSION="1.6.2"
        echo "Version Override: $VERSION"
    fi
    if [ "${CONNECTOR_PACKAGE_LIST[$i]}" = "kafka-connect-salesforce" ];
    then
        VERSION="2.0.25"
        echo "Version Override: $VERSION"
    fi

    if [ -z "$CONNECTOR_VERSION_LIST_CONFLUENTHUB" ];
    then
        CONNECTOR_VERSION_LIST_CONFLUENTHUB="$VERSION"
    else
        CONNECTOR_VERSION_LIST_CONFLUENTHUB+=" $VERSION"
    fi
done
