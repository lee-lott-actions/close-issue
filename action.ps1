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

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$RepoName/issues/$IssueNumber"

    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github+json"
		"X-GitHub-Api-Version" = "2026-03-10"
        "Content-Type" = "application/json"
    }

    $body = @{ state = 'closed' } | ConvertTo-Json

    try {
        Write-Host "Attempting to close issue #$IssueNumber in $Owner/$RepoName"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Patch -Body $body

        if ($response.StatusCode -eq 200) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
            Write-Host "Closed issue #$IssueNumber in $Owner/$RepoName"
        } else {
			$errorMsg = "Error: Failed to close issue #$IssueNumber. Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
            Write-Host $errorMsg
        }
    } catch {
		$errorMsg = "Error: Failed to close issue #$IssueNumber. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}
