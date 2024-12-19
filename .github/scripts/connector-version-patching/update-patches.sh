#!/bin/bash

echo "--- START SCRIPT ---"
echo "Github Token: $GITHUB_TOKEN"
echo "Github Repository: $GITHUB_REPOSITORY"

echo "Connector Count: $CONNECTOR_COUNT"
echo "Connector List to Patch: $CONNECTOR_LIST_TO_PATCH"
CONNECTOR_LIST_TO_PATCH=($CONNECTOR_LIST_TO_PATCH)
echo "Connector Versions: $CONNECTOR_VERSIONS"
CONNECTOR_VERSIONS=($CONNECTOR_VERSIONS)
echo "Connector Versions Confluent Hub: $CONNECTOR_VERSIONS_CONFLUENTHUB"
CONNECTOR_VERSIONS_CONFLUENTHUB=($CONNECTOR_VERSIONS_CONFLUENTHUB)
echo "Pull Requests to Update: $PULL_REQUESTS_TO_UPDATE"
PULL_REQUESTS_TO_UPDATE=($PULL_REQUESTS_TO_UPDATE)
echo "Valid Pull Requests: $VALID_PULL_REQUESTS"

if [ $VALID_PULL_REQUESTS = "false" ];
then
    echo "No branches / pull requests to update"
fi

for ((i=0; i<$CONNECTOR_COUNT; i++));
do
    if [ "${PULL_REQUESTS_TO_UPDATE[$i]}" != "NULL" ];
    then
        echo "Updating pull request #${PULL_REQUESTS_TO_UPDATE[$i]}..."

        echo "Fetching pull request branch..."
        PULL_REQUEST=$(curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/${PULL_REQUESTS_TO_UPDATE[$i]}")
        PULL_REQUEST_BRANCH=$(echo "$PULL_REQUEST" | jq --raw-output '.head.ref')
        echo "Pull Request Branch: $PULL_REQUEST_BRANCH"

        echo "Checking out pull request branch..."
        git checkout -b "$PULL_REQUEST_BRANCH" origin/"$PULL_REQUEST_BRANCH"
        git branch

        echo "Applying changes to configuration file..."
        echo "New version to apply: ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"

        export CHUB_CONNECTOR_NAME="${CONNECTOR_LIST_TO_PATCH[$i]}"
        export CHUB_VERSION="${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"

        yq eval -i '(.spec.build.onDemand.plugins.confluentHub[] | select(.name == env(CHUB_CONNECTOR_NAME)).version) |= env(CHUB_VERSION)' $KAFKA_CONNECT_BASE_CONFIGURATION_FILE

        echo "Committing changes to branch..."
        git config user.name "$GITHUB_ACTIONS_BOT_NAME"
        git config user.email "$GITHUB_ACTIONS_BOT_EMAIL"
        git add "$KAFKA_CONNECT_BASE_CONFIGURATION_FILE"
        git commit -m "Update ${CONNECTOR_LIST_TO_PATCH[$i]} connector version to ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"
        echo "Pushing committed changes to remote branch..."
        git push -u origin "${PULL_REQUEST_BRANCH}"

        echo "Updating pull request with changes..."
        PULL_REQUEST_TITLE="Patch ${CONNECTOR_LIST_TO_PATCH[$i]} Connector Version from ${CONNECTOR_VERSIONS[$i]} to ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"
        echo "Title: $PULL_REQUEST_TITLE"
        PULL_REQUEST_BODY="$PULL_REQUEST_TITLE in $KAFKA_CONNECT_BASE_CONFIGURATION_FILE"
        echo "Body: $PULL_REQUEST_BODY"

        UPDATED_PULL_REQUEST=$(curl -X PATCH -H "Authorization: token $GITHUB_TOKEN" "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/${PULL_REQUESTS_TO_UPDATE[$i]}" -d '{"title":'\""$PULL_REQUEST_TITLE"\"',"body":'\""$PULL_REQUEST_BODY"\"'}')
        echo "$UPDATED_PULL_REQUEST"
        PULL_REQUEST_NUMBER="$(echo $UPDATED_PULL_REQUEST | jq --raw-output '.number')"
        if [ -z "$PULL_REQUEST_NUMBER" ] || [ "$PULL_REQUEST_NUMBER" = "" ] || [ "$PULL_REQUEST_NUMBER" = "null" ];
        then
            echo "Failed to update pull request"
        else
            echo "Updated pull request #$PULL_REQUEST_NUMBER successfully"
        fi
    fi
done
