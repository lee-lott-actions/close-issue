#!/bin/bash

close_issue() {
  local issue_number="$1"
  local token="$2"
  local owner="$3"
  local repo_name="$4"

  # Validate required inputs
  if [ -z "$issue_number" ] || [ -z "$repo_name" ] || [ -z "$owner" ] || [ -z "$token" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Attempting to close issue #$issue_number in $owner/$repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"

  RESPONSE=$(curl -s -o response.json -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    "$api_base_url/repos/$owner/$repo_name/issues/$issue_number" \
    -d '{"state": "closed"}')

  echo "API Response Code: $RESPONSE"  
  cat response.json

  if [[ "$RESPONSE" == "200" ]]; then
    echo "result=success" >> "$GITHUB_OUTPUT"
    echo "Closed issue #$issue_number in $owner/$repo_name"
  else
    echo "result=failure" >> "$GITHUB_OUTPUT"
    echo "error-message=Failed to close issue #$issue_number. Status: $RESPONSE" >> "$GITHUB_OUTPUT"
    echo "Error: Failed to close issue #$issue_number. Status: $RESPONSE"
  fi

   rm -f response.json
}
