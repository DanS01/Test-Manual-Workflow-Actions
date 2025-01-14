#!/bin/bash

echo "--- START SCRIPT ---"
echo "Github Repository: $GITHUB_REPOSITORY"

echo "Connector Count: $CONNECTOR_COUNT"
echo "Connector List to Patch: $CONNECTOR_LIST_TO_PATCH"
#CONNECTOR_LIST_TO_PATCH=($CONNECTOR_LIST_TO_PATCH)
read -a CONNECTOR_LIST_TO_PATCH <<< "$CONNECTOR_LIST_TO_PATCH"
echo "Connector Versions Confluent Hub: $CONNECTOR_VERSIONS_CONFLUENTHUB"
#CONNECTOR_VERSIONS_CONFLUENTHUB=($CONNECTOR_VERSIONS_CONFLUENTHUB)
read -a CONNECTOR_VERSIONS_CONFLUENTHUB <<< "$CONNECTOR_VERSIONS_CONFLUENTHUB"

REPO_BRANCHES=$(curl --silent -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/branches")
REPO_PULL_REQUESTS=$(curl --silent -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls")

BRANCHES_TO_CREATE=""
PULL_REQUESTS_TO_UPDATE=""

for ((i=0; i<CONNECTOR_COUNT; i++));
do
    if [ "${CONNECTOR_LIST_TO_PATCH[$i]}" == "NULL" ];
    then
        if [ -z "$BRANCHES_TO_CREATE" ];
        then
            BRANCHES_TO_CREATE="NULL"
        else
            BRANCHES_TO_CREATE+=" NULL"
        fi

        if [ -z "$PULL_REQUESTS_TO_UPDATE" ];
        then
            PULL_REQUESTS_TO_UPDATE="NULL"
        else
            PULL_REQUESTS_TO_UPDATE+=" NULL"
        fi
    else
        echo "Checking patch state for connector ${CONNECTOR_LIST_TO_PATCH[$i]}"

        BRANCH_NAME="gha/connector-patching/${CONNECTOR_LIST_TO_PATCH[$i]}"
        echo "Branch Name: $BRANCH_NAME"

        REPO_PATCH_BRANCH_NAME=$(echo "$REPO_BRANCHES" | jq --raw-output '.[] | select(.name == '\""${BRANCH_NAME}\""') | .name')

        if [ -z "$REPO_PATCH_BRANCH_NAME" ];
        then
            echo "Branch does not exist in repository"

            if [ -z "$BRANCHES_TO_CREATE" ];
            then
                BRANCHES_TO_CREATE="$BRANCH_NAME"
                PULL_REQUESTS_TO_UPDATE="NULL"
            else
                BRANCHES_TO_CREATE+=" $BRANCH_NAME"
                PULL_REQUESTS_TO_UPDATE+=" NULL"
            fi
        else
            echo "Branch exists in repository"

            if [ -z "$BRANCHES_TO_CREATE" ];
            then
                BRANCHES_TO_CREATE="NULL"
            else
                BRANCHES_TO_CREATE+=" NULL"
            fi

            REPO_PATCH_PULLREQUEST_NUMBER=$(echo "$REPO_PULL_REQUESTS" | jq --raw-output '.[] | select(.head.ref == '\""${BRANCH_NAME}"\"') | .number')

            if [ -z "$REPO_PATCH_PULLREQUEST_NUMBER" ];
            then
                echo "Pull Request does not exist in repository"

                if [ -z "$PULL_REQUESTS_TO_UPDATE" ];
                then
                    PULL_REQUESTS_TO_UPDATE="NULL"
                else
                    PULL_REQUESTS_TO_UPDATE+=" NULL"
                fi
            else
                echo "Pull Request exists in repository as PR#$REPO_PATCH_PULLREQUEST_NUMBER"

                REPO_PATCH_PULLREQUEST_TITLE=$(echo "$REPO_PULL_REQUESTS" | jq --raw-output '.[] | select(.head.ref == '\""${BRANCH_NAME}"\"') | .title')
                echo "PR Title: $REPO_PATCH_PULLREQUEST_TITLE"
                echo "CFHUB VERSION: ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"
                # Grep command returns with exit code 0 (success) on match and exit code 1 (failure) on no match which will cause the GitHub job to fail
                # Append conditional true to the command to force an exit code of 0 (success) in the case of no matches and continue processing
                PATCHED_VERSION_MATCHES=$(echo "$REPO_PATCH_PULLREQUEST_TITLE" | grep "${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}" || true)
                echo $?
                echo "Patched Version Matches: $PATCHED_VERSION_MATCHES"
                
                if [ -z "$PATCHED_VERSION_MATCHES" ];
                then
                    echo "Patched connector version does not match the Confluent Hub version ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]} and needs to be patched"
                    if [ -z "$PULL_REQUESTS_TO_UPDATE" ];
                    then
                        PULL_REQUESTS_TO_UPDATE="$REPO_PATCH_PULLREQUEST_NUMBER"
                    else
                        PULL_REQUESTS_TO_UPDATE+=" $REPO_PATCH_PULLREQUEST_NUMBER"
                    fi
                else
                    echo "Patched connector version matches so ignoring the patch"
                    if [ -z "$PULL_REQUESTS_TO_UPDATE" ];
                    then
                        PULL_REQUESTS_TO_UPDATE="NULL"
                    else
                        PULL_REQUESTS_TO_UPDATE+=" NULL"
                    fi
                fi
            fi
        fi
    fi
done

VALID_BRANCHES="false"
VALID_PULL_REQUESTS="false"

echo ""
echo "List of branches to create:"
#BRANCHES_TO_CREATE_DISPLAY=($BRANCHES_TO_CREATE)
read -a BRANCHES_TO_CREATE_DISPLAY <<< "$BRANCHES_TO_CREATE"
for ((i=0; i<$CONNECTOR_COUNT; i++));
do
    if [ "${BRANCHES_TO_CREATE_DISPLAY[$i]}" != "NULL" ];
    then
        echo "${BRANCHES_TO_CREATE_DISPLAY[$i]}"
        VALID_BRANCHES="true"
    fi
done

echo ""
echo "List of pull requests to update:"
#PULL_REQUESTS_TO_UPDATE_DISPLAY=($PULL_REQUESTS_TO_UPDATE)
read -a PULL_REQUESTS_TO_UPDATE_DISPLAY <<< "$PULL_REQUESTS_TO_UPDATE"
for ((i=0; i<$CONNECTOR_COUNT; i++));
do
    if [ "${PULL_REQUESTS_TO_UPDATE_DISPLAY[$i]}" != "NULL" ];
    then
        echo "PR#${PULL_REQUESTS_TO_UPDATE_DISPLAY[$i]}"
        VALID_PULL_REQUESTS="true"
    fi
done

echo ""
echo "Flag VALID_BRANCHES set to $VALID_BRANCHES"
echo "Flag VALID_PULL_REQUESTS set to $VALID_PULL_REQUESTS"
