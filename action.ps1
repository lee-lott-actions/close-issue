function Close-Issue {
    param(
        [string]$IssueNumber,
        [string]$Token,
        [string]$Owner,
        [string]$RepoName
    )

    # Validate required inputs
    if ([string]::IsNullOrEmpty($IssueNumber) -or
        [string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Output "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Host "Attempting to close issue #$IssueNumber in $Owner/$RepoName"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$RepoName/issues/$IssueNumber"

    $headers = @{
        Authorization  = "Bearer $Token"
        Accept         = "application/vnd.github.v3+json"
        "Content-Type" = "application/json"
        "User-Agent"   = "pwsh-action"
    }

    $jsonBody = @{ state = 'closed' } | ConvertTo-Json

    try {
        Write-Host "Sending PATCH request to $uri"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Patch -Body $jsonBody -ErrorAction Stop

        Write-Host "API Response Code: $($response.StatusCode)"
        Write-Host $response.Content

        if ($response.StatusCode -eq 200) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
            Write-Host "Closed issue #$IssueNumber in $Owner/$RepoName"
        } else {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to close issue #$IssueNumber. Status: $($response.StatusCode)"
            Write-Host "Error: Failed to close issue #$IssueNumber. Status: $($response.StatusCode)"
        }
    } catch {
        $httpStatus = $_.Exception.Response.StatusCode.value__
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to close issue #$IssueNumber. Status: $httpStatus"
        Write-Host "Error: Failed to close issue #$IssueNumber. Status: $httpStatus"
    }
}