# Close Issue Action

This GitHub Action closes a specified GitHub issue using the GitHub API. It returns the result of the closure attempt, indicating success or failure, along with an error message if the operation fails.

## Features
- Closes a GitHub issue by making a PATCH request to the GitHub API.
- Outputs the result of the closure attempt (`success` or `failure`) and an error message if applicable.
- Requires a GitHub token with repository write access for authentication.

## Inputs
| Name          | Description                                      | Required | Default |
|---------------|--------------------------------------------------|----------|---------|
| `issue-number`| The issue number to close.                      | Yes      | N/A     |
| `token`       | GitHub token with repository write access.      | Yes      | N/A     |
| `owner`       | The owner of the organization (user or organization). | Yes | N/A    |
| `repo-name`  | The repository name to which the issue is assigned.    | Yes      | N/A     |

## Outputs
| Name           | Description                                           |
|----------------|-------------------------------------------------------|
| `result`       | Result of the issue closure attempt ("success" or "failure"). |
| `error-message`| Error message if the issue closure fails.             |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/close-issue.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: Close Issue
   on:
     issues:
       types: [labeled]
   jobs:
     close-issue:
       runs-on: ubuntu-latest
       steps:
         - name: Close Issue
           id: close
           uses: lee-lott-actions/close-issue-action@v1.0.0
           with:
             issue-number: ${{ github.event.issue.number }}
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
             repo-name: ${{ github.event.repository.name }}
         - name: Print Result
           run: |
             if [[ "${{ steps.close.outputs.result }}" == "success" ]]; then
               echo "Issue #${{ github.event.issue.number }} successfully closed."
             else
               echo "Error: ${{ steps.close.outputs.error-message }}"
               exit 1
             fi
