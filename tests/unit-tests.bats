#!/usr/bin/env bats

# Load the Bash script containing the close_issue function
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  local output_file="response.json"

  # Copy the mock response to the specified output file
  cat "$response_file" > "$output_file"
  # Return only the HTTP status code to mimic curl -s -o response.json -w "%{http_code}"
  echo "$http_code"
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response.json "$GITHUB_OUTPUT" mock_response.json
}

@test "unit: close_issue succeeds with HTTP 200" {
  echo '{"state": "closed"}' > mock_response.json
  curl() { mock_curl "200" mock_response.json; }
  export -f curl

  run close_issue "1" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "unit: close_issue fails with HTTP 403" {
  echo '{"message": "Forbidden"}' > mock_response.json
  curl() { mock_curl "403" mock_response.json; }
  export -f curl

  run close_issue "1" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to close issue #1. Status: 403" ]
}

@test "unit: close_issue fails with HTTP 404" {
  echo '{"message": "Issue not found"}' > mock_response.json
  curl() { mock_curl "404" mock_response.json; }
  export -f curl

  run close_issue "1" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to close issue #1. Status: 404" ]
}

@test "unit: close_issue fails with empty issue_number" {
  run close_issue "" "fake-token" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided." ]
}

@test "unit: close_issue fails with empty token" {
  run close_issue "1" "" "test-owner" "test-repo"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided." ]
}

@test "unit: close_issue fails with empty repository" {
  run close_issue "1" "fake-token" "" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided." ]
}
