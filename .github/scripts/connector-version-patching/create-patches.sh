#!/bin/bash

echo "--- START SCRIPT ---"
echo "Github Token: $GITHUB_TOKEN"
echo "Github Repository: $GITHUB_REPOSITORY"

echo "Connector Count: $CONNECTOR_COUNT"
echo "Connector List to Patch: $CONNECTOR_LIST_TO_PATCH"
#CONNECTOR_LIST_TO_PATCH=($CONNECTOR_LIST_TO_PATCH)
read -a CONNECTOR_LIST_TO_PATCH <<< "$CONNECTOR_LIST_TO_PATCH"
echo "Connector Versions: $CONNECTOR_VERSIONS"
#CONNECTOR_VERSIONS=($CONNECTOR_VERSIONS)
read -a CONNECTOR_VERSIONS <<< "$CONNECTOR_VERSIONS"
echo "Connector Versions Confluent Hub: $CONNECTOR_VERSIONS_CONFLUENTHUB"
#CONNECTOR_VERSIONS_CONFLUENTHUB=($CONNECTOR_VERSIONS_CONFLUENTHUB)
read -a CONNECTOR_VERSIONS_CONFLUENTHUB <<< "$CONNECTOR_VERSIONS_CONFLUENTHUB"
echo "Branches to Create: $BRANCHES_TO_CREATE"
#BRANCHES_TO_CREATE=($BRANCHES_TO_CREATE)
read -a BRANCHES_TO_CREATE <<< "$BRANCHES_TO_CREATE"
echo "Valid Branches: $VALID_BRANCHES"

if [ "$VALID_BRANCHES" = "false" ];
then
    echo "No branches / pull requests to create"
fi

for ((i=0; i<CONNECTOR_COUNT; i++));
do
    if [ "${BRANCHES_TO_CREATE[$i]}" != "NULL" ];
    then
        echo "Creating branch ${BRANCHES_TO_CREATE[$i]}..."
        git checkout -b "${BRANCHES_TO_CREATE[$i]}" origin/"$REPOSITORY_BASE_BRANCH"
        git branch

        echo "Applying changes to configuration file..."
        echo "New version to apply: ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"

        export CHUB_CONNECTOR_NAME="${CONNECTOR_LIST_TO_PATCH[$i]}"
        export CHUB_VERSION="${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"

        yq eval -i '(.spec.build.onDemand.plugins.confluentHub[] | select(.name == env(CHUB_CONNECTOR_NAME)).version) |= env(CHUB_VERSION)' "$KAFKA_CONNECT_BASE_CONFIGURATION_FILE"

        echo "Committing changes to branch..."
        git config user.name "$GITHUB_ACTIONS_BOT_NAME"
        git config user.email "$GITHUB_ACTIONS_BOT_EMAIL"
        git add "$KAFKA_CONNECT_BASE_CONFIGURATION_FILE"
        git commit -m "Update ${CONNECTOR_LIST_TO_PATCH[$i]} connector version to ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"
        echo "Pushing committed changes to remote branch..."
        git push -u origin "${BRANCHES_TO_CREATE[$i]}"

        echo "Creating pull request of changes..."
        echo "Base Branch: $REPOSITORY_BASE_BRANCH"
        PULL_REQUEST_TITLE="Patch ${CONNECTOR_LIST_TO_PATCH[$i]} Connector Version from ${CONNECTOR_VERSIONS[$i]} to ${CONNECTOR_VERSIONS_CONFLUENTHUB[$i]}"
        echo "Title: $PULL_REQUEST_TITLE"
        PULL_REQUEST_BODY="$PULL_REQUEST_TITLE in $KAFKA_CONNECT_BASE_CONFIGURATION_FILE"
        echo "Body: $PULL_REQUEST_BODY"

        REPO_BRANCHES=$(curl --silent -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/branches")
        echo "$REPO_BRANCHES"

        CREATED_PULL_REQUEST=$( curl -X POST -H "Authorization: token $GITHUB_TOKEN" "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls" -d '{"title":'\""$PULL_REQUEST_TITLE"\"',"body":'\""$PULL_REQUEST_BODY"\"',"head":'\""${BRANCHES_TO_CREATE[$i]}"\"',"base":'\""$REPOSITORY_BASE_BRANCH"\"',"draft":false}' )
        echo "$CREATED_PULL_REQUEST"
        PULL_REQUEST_NUMBER="$(echo $CREATED_PULL_REQUEST | jq --raw-output '.number')"
        if [ -z "$PULL_REQUEST_NUMBER" ] || [ "$PULL_REQUEST_NUMBER" = "" ] || [ "$PULL_REQUEST_NUMBER" = "null" ];
        then
            echo "Failed to create pull request"
        else
            echo "Created pull request #$PULL_REQUEST_NUMBER successfully"
        fi
    fi
done
