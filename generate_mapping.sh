#!/bin/bash

# Truncate the mapping.properties file
truncate -s 0 mapping.properties
# Iterate through all Quarkiverse repositories and generate a mapping file
gh repo list quarkusio --jq '.[].nameWithOwner' --topic automated-release --json nameWithOwner --no-archived -L 1000 |  sort | while read repo; do
  # Get the groupId from the pom.xml file
  groupId=$(gh api -H "Accept: application/vnd.github.raw" /repos/$repo/contents/pom.xml 2>/dev/null | xmllint --xpath "//*[local-name()='project']/*[local-name()='groupId']/text()" - 2>/dev/null)
  # If the groupId is not empty, print the repository name
  if [ -n "$groupId" ]; then
    # Print the repository name and the groupId
    echo -e "$repo=$groupId"
    # Append the repository name and the groupId to the mapping.properties file
    echo -e "$repo=$groupId" >> mapping.properties
  fi
done
